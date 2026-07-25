import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order_model.dart';
import 'cancel_order_screen.dart';
import 'order_tracking_screen.dart';
import 'rate_product_screen.dart';
import 'report_issue_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.primaryGreen;
      case 'Shipped':
        return Colors.blue;
      case 'New':
      case 'Accepted':
      case 'Packed':
        return Colors.orange;
      case 'Declined':
      case 'Cancelled':
      case 'Auto-Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDisplayStatus(String status) {
    if (['New', 'Accepted', 'Packed'].contains(status)) return 'Processing';
    if (['Declined', 'Auto-Cancelled'].contains(status)) return 'Cancelled';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Order Details",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Help Support action
            },
            child: const Text("Help", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found."));
          }

          final order = OrderModel.fromJson(snapshot.data!.data() as Map<String, dynamic>);
          final displayStatus = _getDisplayStatus(order.orderStatus);
          final statusColor = _getStatusColor(order.orderStatus);
          final dateFormat = DateFormat('dd MMM, yyyy • hh:mm a');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Order ID: ${order.orderId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Placed on ${dateFormat.format(order.createdAt)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          displayStatus,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // Delivery Address
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Delivery Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        order.deliveryAddress,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                      ),
                      if (order.customerPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(order.customerPhone, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      ]
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Items
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Items (${order.items.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey.shade100, width: 56, height: 56),
                                errorWidget: (context, url, error) => Container(color: Colors.grey.shade100, width: 56, height: 56, child: const Icon(Icons.image, color: Colors.grey)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(item.variantLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("₹${item.price.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text("Qty: ${item.quantity}", style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500)),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      )),
                      const Divider(height: 24),
                      _buildBillRow("Item Total", "₹${order.subTotal.toInt()}"),
                      const SizedBox(height: 8),
                      _buildBillRow(
                        "Delivery Fee",
                        order.deliveryFee == 0 ? "FREE" : "₹${order.deliveryFee.toInt()}",
                        valueColor: order.deliveryFee == 0 ? AppColors.primaryGreen : Colors.black87,
                      ),
                      if (order.platformFee > 0) ...[
                        const SizedBox(height: 8),
                        _buildBillRow("Platform Fee", "₹${order.platformFee.toInt()}"),
                      ],
                      if (order.taxes > 0) ...[
                        const SizedBox(height: 8),
                        _buildBillRow("Taxes", "₹${order.taxes.toInt()}"),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("₹${order.totalAmount.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Status Footer Message
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text(
                        _getFooterStatusMessage(order.orderStatus),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                if (order.orderStatus == 'Delivered') ...[
                  Builder(
                    builder: (context) {
                      final canReport = _canReportIssue(order);

                      if (order.isIssueReported) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.issueStatus == 'Approved by Vendor' 
                                          ? "Refund Approved"
                                          : order.issueStatus == 'Disputed'
                                              ? "Issue Disputed"
                                              : order.issueStatus == 'Refund Processed'
                                                  ? "Refund Processed"
                                                  : order.issueStatus == 'Rejected'
                                                      ? "Refund Rejected"
                                                      : "Issue Reported", 
                                      style: const TextStyle(fontWeight: FontWeight.bold)
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.issueStatus == 'Approved by Vendor'
                                          ? "The vendor approved your request. The refund will reflect in your original payment method in 3-5 business days. Please discard the affected items."
                                          : order.issueStatus == 'Disputed'
                                              ? "The vendor has disputed this claim. The FreshGa admin team is reviewing the case and will contact you shortly."
                                              : order.issueStatus == 'Refund Processed'
                                                  ? "Your refund has been successfully processed to your original payment method."
                                                  : order.issueStatus == 'Rejected'
                                                      ? "Unfortunately, your refund request was rejected after review."
                                                      : "Your issue has been sent to the vendor for review. We will update you soon.",
                                      style: TextStyle(color: Colors.blue.shade900, fontSize: 12)
                                    ),
                                  ]
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (canReport) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Didn't receive your order?", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text("Report an issue within 24 hours for a full refund.", style: TextStyle(color: Colors.orange.shade900, fontSize: 12)),
                                  ]
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ReportIssueScreen(order: order)),
                                  );
                                  if (result == true) {
                                    // In a real app, this page would rebuild automatically 
                                    // if it's using a StreamBuilder for the order.
                                  }
                                },
                                child: const Text("Report", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        );
                      }
                      return const SizedBox();
                    }
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Action Buttons
                Column(
                  children: [
                    if (order.orderStatus == 'New') ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CancelOrderScreen(order: order)),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Cancel Order", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order.orderStatus == 'Delivered') ...[
                      if (!order.isRated) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RateProductScreen(order: order)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.primaryGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Rate Products", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!order.isIssueReported && _canReportIssue(order)) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ReportIssueScreen(order: order)),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Report Issue / Refund", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                    if (['New', 'Accepted', 'Packed', 'Shipped'].contains(order.orderStatus)) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.primaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Track Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillRow(String title, String value, {Color valueColor = Colors.black87}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  String _getFooterStatusMessage(String status) {
    switch (status) {
      case 'New': return "Waiting for store to accept your order.";
      case 'Accepted': return "Store has accepted your order.";
      case 'Packed': return "Your order is packed and ready to ship.";
      case 'Shipped': return "Your order is on the way.";
      case 'Delivered': return "This order has been delivered.";
      case 'Declined': return "The store declined this order.";
      case 'Cancelled': return "You cancelled this order.";
      case 'Auto-Cancelled': return "Order was auto-cancelled due to no response.";
      default: return "";
    }
  }

  bool _canReportIssue(OrderModel order) {
    if (order.orderStatus != 'Delivered') return false;
    final deliveredEvent = order.timeline.reversed.firstWhere(
      (e) => e['status'] == 'Delivered', 
      orElse: () => {'timestamp': order.updatedAt.toIso8601String()}
    );
    final deliveredDate = DateTime.parse(deliveredEvent['timestamp'] ?? order.updatedAt.toIso8601String());
    return DateTime.now().difference(deliveredDate).inHours <= 24;
  }
}
