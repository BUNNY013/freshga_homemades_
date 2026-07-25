import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order_model.dart';
import 'refund_status_screen.dart';

class CancelOrderScreen extends StatefulWidget {
  final OrderModel order;

  const CancelOrderScreen({super.key, required this.order});

  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  final List<String> _reasons = [
    'Ordered by mistake',
    'Want to change the delivery address',
    'Delivery is taking too long',
    'Found a better price',
    'Other reason'
  ];

  String _selectedReason = 'Ordered by mistake';
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  void _showCancelConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.red, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Cancel this order?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  "If you cancel now, your refund (if applicable) will be initiated.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      _processCancellation();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Yes, Cancel Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("No, Go Back", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processCancellation() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now().toIso8601String();
      final timeline = List<Map<String, dynamic>>.from(widget.order.timeline);
      
      String note = _selectedReason;
      if (_noteController.text.trim().isNotEmpty) {
        note += " - ${_noteController.text.trim()}";
      }

      timeline.add({
        'status': 'Cancelled',
        'time': now,
        'note': note,
      });

      await FirebaseFirestore.instance.collection('orders').doc(widget.order.orderId).update({
        'orderStatus': 'Cancelled',
        'timeline': timeline,
        'updatedAt': now,
      });

      if (!mounted) return;

      // Navigate to Refund Screen if a payment was made, else pop to My Orders
      // Assuming 'Success' or 'Paid' means payment was collected by platform.
      if (widget.order.paymentStatus != 'Pending' && widget.order.paymentStatus != 'Failed') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RefundStatusScreen(order: widget.order)),
        );
      } else {
        // Pop back to My Orders screen (pop twice: details screen and this screen)
        Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == '/orders');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Cancelled Successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final storeName = "Store"; // Ideally passed down or fetched

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cancel Order",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Info Summary
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order ID: ${order.orderId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text("${order.items.length} items • ₹${order.totalAmount.toInt()}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (order.items.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: order.items.first.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey.shade100, width: 48, height: 48),
                          errorWidget: (context, url, error) => Container(color: Colors.grey.shade100, width: 48, height: 48, child: const Icon(Icons.image, color: Colors.grey)),
                        ),
                      ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1),
                ),
                
                // Reasons
                const Text("Select Reason", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                
                ..._reasons.map((reason) => InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _selectedReason == reason ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: _selectedReason == reason ? AppColors.primaryGreen : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 12),
                        Text(reason, style: TextStyle(fontSize: 14, color: _selectedReason == reason ? Colors.black87 : Colors.grey.shade700)),
                      ],
                    ),
                  ),
                )),
                
                const SizedBox(height: 24),
                
                // Note textfield
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  maxLength: 150,
                  decoration: InputDecoration(
                    hintText: "Add a note (optional)\nTell us more...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryGreen),
                    ),
                  ),
                ),
                
                const SizedBox(height: 100), // padding for bottom button
              ],
            ),
          ),
          
          // Bottom Action Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _showCancelConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Cancel Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
