import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order_model.dart';
import '../../../models/store_model.dart';
import '../../../services/store_service.dart';

class RefundStatusScreen extends StatefulWidget {
  final OrderModel order;

  const RefundStatusScreen({super.key, required this.order});

  @override
  State<RefundStatusScreen> createState() => _RefundStatusScreenState();
}

class _RefundStatusScreenState extends State<RefundStatusScreen> {
  StoreModel? _store;
  bool _isLoadingStore = true;

  @override
  void initState() {
    super.initState();
    _fetchStore();
  }

  Future<void> _fetchStore() async {
    final store = await StoreService().getStore(widget.order.storeId);
    if (mounted) {
      setState(() {
        _store = store;
        _isLoadingStore = false;
      });
    }
  }

  // Helper to find cancellation time
  DateTime _getCancellationTime() {
    final cancelEvent = widget.order.timeline.lastWhere(
      (event) => event['status'] == 'Cancelled' || event['status'] == 'Auto-Cancelled' || event['status'] == 'Declined',
      orElse: () => {'time': widget.order.updatedAt.toIso8601String()},
    );
    return DateTime.parse(cancelEvent['time'] as String);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final cancelTime = _getCancellationTime();
    final dateFormat = DateFormat('dd MMM, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    // Simulate refund steps based on time passed since cancellation
    final now = DateTime.now();
    final durationSinceCancel = now.difference(cancelTime);
    
    final bool isInitiated = true;
    final bool isProcessing = durationSinceCancel.inMinutes > 30;
    final bool isSentToBank = durationSinceCancel.inHours > 24;
    final bool isCredited = durationSinceCancel.inHours > 72; // usually takes 3-5 days

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Because we might have come from CancelOrderScreen, pop to My Orders
            Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == '/orders');
          },
        ),
        title: const Text(
          "Refund Status",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("Help", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCredited ? AppColors.primaryGreen.withOpacity(0.05) : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isCredited ? AppColors.primaryGreen.withOpacity(0.2) : Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(isCredited ? Icons.check_circle : Icons.refresh, color: isCredited ? AppColors.primaryGreen : Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCredited ? "Refund Completed" : "Refund Initiated",
                          style: TextStyle(
                            color: isCredited ? AppColors.primaryGreen : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCredited 
                            ? "Your refund has been successfully credited."
                            : "Your refund is being processed. We will notify you once it is completed.",
                          style: TextStyle(color: isCredited ? AppColors.primaryGreen : Colors.orange.shade800, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Order Summary
            Text("Order ID: ${order.orderId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_store?.name ?? "Loading...", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("${order.items.length} item(s) • ₹${order.totalAmount.toInt()}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                if (order.items.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: order.items.first.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade100, width: 40, height: 40),
                      errorWidget: (context, url, error) => Container(color: Colors.grey.shade100, width: 40, height: 40, child: const Icon(Icons.image, color: Colors.grey)),
                    ),
                  ),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(height: 1),
            ),
            
            const Text("Refund Progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            
            // Timeline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  _buildTimelineStep(
                    title: "Refund Initiated",
                    date: dateFormat.format(cancelTime),
                    time: timeFormat.format(cancelTime),
                    isCompleted: isInitiated,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    title: "Refund Processing",
                    date: isProcessing ? dateFormat.format(cancelTime.add(const Duration(minutes: 30))) : "Expected by ${dateFormat.format(cancelTime.add(const Duration(days: 1)))}",
                    time: isProcessing ? timeFormat.format(cancelTime.add(const Duration(minutes: 30))) : "",
                    isCompleted: isProcessing,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    title: "Refund Sent to Bank",
                    date: isSentToBank ? dateFormat.format(cancelTime.add(const Duration(days: 1))) : "Expected by ${dateFormat.format(cancelTime.add(const Duration(days: 2)))}",
                    time: isSentToBank ? timeFormat.format(cancelTime.add(const Duration(days: 1))) : "",
                    isCompleted: isSentToBank,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    title: "Refund Credited",
                    date: isCredited ? dateFormat.format(cancelTime.add(const Duration(days: 3))) : "Expected by ${dateFormat.format(cancelTime.add(const Duration(days: 5)))}",
                    time: isCredited ? timeFormat.format(cancelTime.add(const Duration(days: 3))) : "",
                    isCompleted: isCredited,
                    isLast: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Footer Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.grey, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Refund amount will be credited to your original payment method.",
                      style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String date,
    required String time,
    required bool isCompleted,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line and Dot
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primaryGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: isCompleted ? null : Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: isCompleted 
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Icon(Icons.star, size: 12, color: Colors.grey.shade400), // Custom star dot for future
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted ? AppColors.primaryGreen : Colors.grey.shade200,
              )
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isCompleted ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time.isNotEmpty ? "$date • $time" : date,
                  style: TextStyle(color: isCompleted ? Colors.grey.shade600 : Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
