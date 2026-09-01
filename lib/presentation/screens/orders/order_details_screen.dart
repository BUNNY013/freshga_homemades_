import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order_model.dart';
import 'cancel_order_screen.dart';
import 'order_tracking_screen.dart';
import 'rate_product_screen.dart';
import 'report_issue_screen.dart';
import 'order_help_screen.dart';

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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              backgroundColor: Colors.grey.shade50,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Order Details",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              backgroundColor: Colors.grey.shade50,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Order Details",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            body: const Center(child: Text("Order not found.")),
          );
        }

        final order = OrderModel.fromJson(
          snapshot.data!.data() as Map<String, dynamic>,
        );
        final displayStatus = _getDisplayStatus(order.orderStatus);
        final statusColor = _getStatusColor(order.orderStatus);
        final dateFormat = DateFormat('dd MMM, yyyy • hh:mm a');

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
              "Order Details",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderHelpScreen(order: order),
                    ),
                  );
                },
                child: const Text(
                  "Help",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info & Tracking
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Order ID: ${order.orderId}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Placed on ${dateFormat.format(order.createdAt)}",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              displayStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Color(0xFFF5F5F5)),
                      ),
                      _AnimatedTrackingTimeline(order: order),
                    ],
                  ),
                ),

                if (order.shippingMethod.isNotEmpty ||
                    order.trackingId.isNotEmpty ||
                    order.receiptImageUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Dispatch Details",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (order.shippingMethod.isNotEmpty)
                          _buildDetailRow(
                            "Shipping Method",
                            order.shippingMethod,
                          ),
                        if (order.shippingProvider.isNotEmpty)
                          _buildDetailRow(
                            "Shipping Provider",
                            order.shippingProvider,
                          ),
                        if (order.trackingId.isNotEmpty)
                          _buildDetailRow("Tracking ID", order.trackingId),
                        if (order.trackingLink.isNotEmpty)
                          _buildDetailRow(
                            "Tracking Link",
                            order.trackingLink,
                            isLink: true,
                          ),
                        if (order.contactNumber.isNotEmpty)
                          _buildDetailRow(
                            "Contact Number",
                            order.contactNumber,
                          ),
                        if (order.receiptNumber.isNotEmpty)
                          _buildDetailRow(
                            "Receipt Number",
                            order.receiptNumber,
                          ),
                        if (order.deliveryTime.isNotEmpty)
                          _buildDetailRow(
                            "Expected Delivery",
                            order.deliveryTime,
                          ),
                        if (order.receiptImageUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(16),
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      InteractiveViewer(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: order.receiptImageUrl,
                                            placeholder: (context, url) =>
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "View Receipt / Proof",
                                    style: TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Delivery Address
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Delivery Address",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.deliveryAddress,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                if (order.customerPhone.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    order.customerPhone,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Items & Bill
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Items (${order.items.length})",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: item.imageUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade100,
                                      width: 64,
                                      height: 64,
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: Colors.grey.shade100,
                                          width: 64,
                                          height: 64,
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (item.variantLabel.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.variantLabel,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "₹${item.price.toInt()}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            "Qty: ${item.quantity}",
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: Color(0xFFF5F5F5)),
                      ),
                      const SizedBox(height: 8),
                      _buildBillRow("Item Total", "₹${order.subTotal.toInt()}"),
                      const SizedBox(height: 12),
                      _buildBillRow(
                        "Delivery Fee",
                        order.deliveryFee == 0
                            ? "FREE"
                            : "₹${order.deliveryFee.toInt()}",
                        valueColor: order.deliveryFee == 0
                            ? AppColors.primaryGreen
                            : Colors.black87,
                      ),
                      if (order.platformFee > 0) ...[
                        const SizedBox(height: 12),
                        _buildBillRow(
                          "Platform Fee",
                          "₹${order.platformFee.toInt()}",
                        ),
                      ],
                      if (order.taxes > 0) ...[
                        const SizedBox(height: 12),
                        _buildBillRow("Taxes", "₹${order.taxes.toInt()}"),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Color(0xFFF5F5F5)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            "₹${order.totalAmount.toInt()}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppColors.primaryGreen,
                            ),
                          ),
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
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getFooterStatusMessage(order.orderStatus),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade100),
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
                                          : order.issueStatus ==
                                                'Refund Processed'
                                          ? "Refund Processed"
                                          : order.issueStatus == 'Rejected'
                                          ? "Refund Rejected"
                                          : "Issue Reported",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.issueStatus == 'Approved by Vendor'
                                          ? "The vendor approved your request. The refund will reflect in your original payment method in 3-5 business days. Please discard the affected items."
                                          : order.issueStatus == 'Disputed'
                                          ? "The vendor has disputed this claim. The FreshGa admin team is reviewing the case and will contact you shortly."
                                          : order.issueStatus ==
                                                'Refund Processed'
                                          ? "Your refund has been successfully processed to your original payment method."
                                          : order.issueStatus == 'Rejected'
                                          ? "Unfortunately, your refund request was rejected after review."
                                          : "Your issue has been sent to the vendor for review. We will update you soon.",
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
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
                            borderRadius: BorderRadius.circular(20),
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
                                    const Text(
                                      "Didn't receive your order?",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Report an issue within 24 hours for a full refund.",
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ReportIssueScreen(order: order),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Report",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox();
                    },
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
                              MaterialPageRoute(
                                builder: (_) => CancelOrderScreen(order: order),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Cancel Order",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RateProductScreen(order: order),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primaryGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Rate Products",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReportIssueScreen(order: order),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Report Issue / Refund",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillRow(
    String title,
    String value, {
    Color valueColor = Colors.black87,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _getFooterStatusMessage(String status) {
    switch (status) {
      case 'New':
        return "Waiting for store to accept your order.";
      case 'Accepted':
        return "Store has accepted your order.";
      case 'Packed':
        return "Your order is packed and ready to ship.";
      case 'Shipped':
        return "Your order is on the way.";
      case 'Delivered':
        return "This order has been delivered.";
      case 'Declined':
        return "The store declined this order.";
      case 'Cancelled':
        return "You cancelled this order.";
      case 'Auto-Cancelled':
        return "Order was auto-cancelled due to no response.";
      default:
        return "";
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: isLink
                  ? () async {
                      final uri = Uri.tryParse(value);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    }
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  color: isLink ? Colors.blue : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: isLink
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canReportIssue(OrderModel order) {
    if (order.orderStatus != 'Delivered') return false;
    final deliveredEvent = order.timeline.reversed.firstWhere(
      (e) => e['status'] == 'Delivered',
      orElse: () => {'timestamp': order.updatedAt.toIso8601String()},
    );
    final deliveredDate = DateTime.parse(
      deliveredEvent['timestamp'] ?? order.updatedAt.toIso8601String(),
    );
    return DateTime.now().difference(deliveredDate).inHours <= 24;
  }
}

class _AnimatedTrackingTimeline extends StatelessWidget {
  final OrderModel order;

  const _AnimatedTrackingTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus;
    // Determine current step index
    final steps = ['New', 'Accepted', 'Packed', 'Shipped', 'Delivered'];
    int currentIndex = steps.indexOf(status);

    // Handle cancelled cases
    if (['Declined', 'Cancelled', 'Auto-Cancelled'].contains(status)) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              "Order Cancelled",
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (currentIndex == -1) currentIndex = 0; // Fallback

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Column(
        children: List.generate(steps.length, (index) {
          final stepName = steps[index];
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final isLast = index == steps.length - 1;

          // Find timestamp for this step
          String? timeString;
          try {
            final event = order.timeline.lastWhere(
              (e) => e['status'] == stepName,
            );
            final rawTime = event['timestamp'] ?? event['time'];
            if (rawTime != null) {
              timeString = DateFormat(
                'dd MMM, hh:mm a',
              ).format(DateTime.parse(rawTime.toString()));
            }
          } catch (e) {
            // No event found for this step yet
            if (stepName == 'New') {
              timeString = DateFormat(
                'dd MMM, hh:mm a',
              ).format(order.createdAt);
            } else if (stepName == 'Delivered') {
              if (order.deliveryTime.isNotEmpty) {
                timeString = "Expected: ${order.deliveryTime}";
              } else {
                final est = order.maxDispatchDate.add(const Duration(days: 5));
                timeString = "Expected by ${DateFormat('dd MMM').format(est)}";
              }
            }
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 400 + (index * 200)),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: isCompleted ? value : 1.0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.primaryGreen
                                : Colors.grey.shade200,
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryGreen.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  if (!isLast)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 2,
                      height: 36,
                      color: index < currentIndex
                          ? AppColors.primaryGreen
                          : Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0, bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepName,
                        style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : (isCompleted
                                    ? FontWeight.w700
                                    : FontWeight.w500),
                          color: isCompleted
                              ? AppColors.textPrimary
                              : Colors.grey.shade400,
                          fontSize: 15,
                        ),
                      ),
                      if (timeString != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          timeString,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
