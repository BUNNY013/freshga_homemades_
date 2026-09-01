import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order_model.dart';
import 'cancel_order_screen.dart';
import 'report_issue_screen.dart';

class OrderHelpScreen extends StatelessWidget {
  final OrderModel order;

  const OrderHelpScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final bool isDelivered = order.orderStatus == 'Delivered';
    final bool isNew =
        order.orderStatus == 'New' || order.orderStatus == 'Accepted';
    final bool isProcessing =
        order.orderStatus == 'Packed' || order.orderStatus == 'Shipped';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Help & Support",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContextCard(),
                  const SizedBox(height: 24),
                  const Text(
                    "What do you need help with?",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Topics based on status
                  if (isNew) ...[
                    _buildTopicTile(
                      context,
                      icon: Icons.cancel_outlined,
                      title: "I want to cancel my order",
                      subtitle: "Cancel before the vendor starts preparing",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CancelOrderScreen(order: order),
                          ),
                        );
                      },
                    ),
                    _buildTopicTile(
                      context,
                      icon: Icons.edit_note_rounded,
                      title: "Update delivery instructions",
                      subtitle: "Add instructions for the delivery partner",
                      onTap: () =>
                          _showQueryForm(context, "Update Instructions"),
                    ),
                  ],

                  if (isProcessing) ...[
                    _buildTopicTile(
                      context,
                      icon: Icons.timer_outlined,
                      title: "My order is delayed",
                      subtitle: "Check ETA or speak to an agent",
                      onTap: () => _showQueryForm(context, "Order Delayed"),
                    ),
                    _buildTopicTile(
                      context,
                      icon: Icons.location_on_outlined,
                      title: "Update delivery location",
                      subtitle: "Change address if not too far",
                      onTap: () => _showQueryForm(context, "Change Address"),
                    ),
                  ],

                  if (isDelivered) ...[
                    _buildTopicTile(
                      context,
                      icon: Icons.fastfood_outlined,
                      title: "Items are missing or incorrect",
                      subtitle: "Get a refund or replacement",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportIssueScreen(order: order),
                          ),
                        );
                      },
                    ),
                    _buildTopicTile(
                      context,
                      icon: Icons.star_border_rounded,
                      title: "Food quality issue",
                      subtitle: "Report bad taste, stale food, etc.",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportIssueScreen(order: order),
                          ),
                        );
                      },
                    ),
                    _buildTopicTile(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: "Payment or refund issue",
                      subtitle: "Track refund status or report charge",
                      onTap: () => _showQueryForm(context, "Payment Issue"),
                    ),
                  ],

                  // Fallback for cancelled/declined
                  if (!isNew && !isProcessing && !isDelivered) ...[
                    _buildTopicTile(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: "Refund status",
                      subtitle: "Track your refund for this cancelled order",
                      onTap: () => _showQueryForm(context, "Refund Status"),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text(
                    "Other Queries",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTopicTile(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: "General FAQs",
                    subtitle: "Read common questions",
                    onTap: () => _showQueryForm(context, "FAQs"),
                  ),
                ],
              ),
            ),
          ),

          // Contact Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall('18001234567'),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text("Call Support"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showQueryForm(context, "General Query"),
                    icon: const Icon(Icons.edit_document, size: 18),
                    label: const Text("Submit Query"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_outlined,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.storeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Order ID: ${order.orderId}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(order.createdAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.orderStatus,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        debugPrint("Could not launch $launchUri");
      }
    } catch (e) {
      debugPrint("Could not launch $launchUri");
    }
  }

  void _showQueryForm(BuildContext context, String topic) {
    final TextEditingController messageController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Submit a Query",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Topic: $topic",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Please describe your issue in detail. Our support team will get back to you soon.",
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: messageController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "Type your message here...",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final message = messageController.text
                                        .trim();
                                    if (message.isEmpty) return;

                                    setState(() => isSubmitting = true);

                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('support_tickets')
                                          .add({
                                            'orderId': order.orderId,
                                            'storeId': order.storeId,
                                            'storeName': order.storeName,
                                            'customerId': order.customerId,
                                            'customerName': order.customerName,
                                            'topic': topic,
                                            'message': message,
                                            'status': 'Open',
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                          });

                                      if (context.mounted) {
                                        Navigator.of(context)
                                          ..pop()
                                          ..pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Your query has been submitted successfully!",
                                            ),
                                            backgroundColor:
                                                AppColors.primaryGreen,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setState(() => isSubmitting = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Failed to submit query. Please try again.",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Submit",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
