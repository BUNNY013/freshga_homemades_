import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/customer_provider.dart';
import '../../widgets/shared/bouncing_button.dart';

class TicketDetailsScreen extends StatefulWidget {
  final String ticketId;
  final Map<String, dynamic> initialTicketData;

  const TicketDetailsScreen({
    super.key,
    required this.ticketId,
    required this.initialTicketData,
  });

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final customerId = context.read<CustomerProvider>().currentCustomer?.uid;
    if (customerId == null) return;

    setState(() => _isSending = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Add reply to subcollection
      final replyRef = FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(widget.ticketId)
          .collection('replies')
          .doc();

      batch.set(replyRef, {
        'senderId': customerId,
        'senderType': 'customer',
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update parent ticket timestamp and potentially status if it was waiting
      final ticketRef = FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(widget.ticketId);
      batch.update(ticketRef, {
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        // Optional: change status to Open if it was waiting for customer
      });

      await batch.commit();

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ticket Details",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              "ID: ${widget.ticketId.substring(0, 8).toUpperCase()}",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('support_tickets')
            .doc(widget.ticketId)
            .snapshots(),
        builder: (context, ticketSnapshot) {
          if (ticketSnapshot.hasError)
            return const Center(child: Text("Error loading ticket"));
          if (ticketSnapshot.connectionState == ConnectionState.waiting &&
              !ticketSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          final ticketData =
              ticketSnapshot.data?.data() as Map<String, dynamic>? ??
              widget.initialTicketData;
          final status = ticketData['status'] ?? 'Open';
          final isClosed = status == 'Resolved' || status == 'Closed';

          return Column(
            children: [
              _buildTicketHeader(ticketData),
              Expanded(child: _buildChatThread()),
              if (isClosed) _buildClosedBanner() else _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTicketHeader(Map<String, dynamic> data) {
    final String topic = data['topic'] ?? 'General Query';
    final String status = data['status'] ?? 'Open';
    final String orderId = data['orderId'] ?? '';
    final bool isResolved = status == 'Resolved' || status == 'Closed';
    final Color statusColor = isResolved
        ? AppColors.primaryGreen
        : Colors.orange;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (orderId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Order ID: $orderId",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatThread() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(widget.ticketId)
          .collection('replies')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text("Failed to load messages"));

        List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

        return ListView.builder(
          controller: _scrollController,
          reverse: true, // Show latest at bottom
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + 1, // +1 for the original message
          itemBuilder: (context, index) {
            if (index == docs.length) {
              // The original ticket message acts as the first message
              final Timestamp? createdAt =
                  widget.initialTicketData['createdAt'] as Timestamp?;
              return _buildMessageBubble(
                message: widget.initialTicketData['message'] ?? '',
                isCustomer: true,
                time: createdAt != null
                    ? DateFormat('hh:mm a').format(createdAt.toDate())
                    : '',
                isOriginal: true,
              );
            }

            final data = docs[index].data() as Map<String, dynamic>;
            final bool isCustomer = data['senderType'] == 'customer';
            final Timestamp? ts = data['timestamp'] as Timestamp?;

            return _buildMessageBubble(
              message: data['message'] ?? '',
              isCustomer: isCustomer,
              time: ts != null
                  ? DateFormat('hh:mm a').format(ts.toDate())
                  : 'Sending...',
              isOriginal: false,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isCustomer,
    required String time,
    required bool isOriginal,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isCustomer
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isCustomer
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCustomer) ...[
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryGreen,
                  child: Icon(
                    Icons.support_agent,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCustomer ? AppColors.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isCustomer
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                      bottomLeft: !isCustomer
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      if (!isCustomer)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isOriginal) ...[
                        Text(
                          "Initial Issue",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCustomer
                                ? Colors.white70
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        message,
                        style: TextStyle(
                          color: isCustomer
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
              left: isCustomer ? 0 : 36,
              right: isCustomer ? 4 : 0,
            ),
            child: Text(
              time,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: "Type a reply...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          BouncingButton(
            onTap: () {
              if (!_isSending) _sendMessage();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.primaryGreen,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            "This ticket has been resolved and closed.",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "If you need further assistance, please create a new ticket.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
