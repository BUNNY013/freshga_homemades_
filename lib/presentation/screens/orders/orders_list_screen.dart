import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/customer_provider.dart';
import '../../../models/order_model.dart';
import '../../../models/store_model.dart';
import '../../../services/store_service.dart';
import 'order_details_screen.dart';
import 'rate_product_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  @override
  Widget build(BuildContext context) {
    final customer = context.read<CustomerProvider>().currentCustomer;

    if (customer == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view orders.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text(
          "My Orders",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
      ),
      body: _OrdersTab(customerId: customer.uid),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final String customerId;
  final List<String> statusFilter;

  const _OrdersTab({required this.customerId, this.statusFilter = const []});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        List<OrderModel> orders = snapshot.data!.docs
            .map((doc) => OrderModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        if (statusFilter.isNotEmpty) {
          orders = orders.where((o) => statusFilter.contains(o.orderStatus)).toList();
        }

        if (orders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _OrderCard(order: orders[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No orders found",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
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
    final order = widget.order;
    final displayStatus = _getDisplayStatus(order.orderStatus);
    final statusColor = _getStatusColor(order.orderStatus);

    // Format Dates
    final DateFormat timeFormat = DateFormat('hh:mm a');
    final DateFormat dateFormat = DateFormat('dd MMM, yyyy');
    
    // Delivery By logic (Fallback to maxDispatchDate + 5 days roughly, or calculate properly)
    final deliveryBy = order.maxDispatchDate.add(const Duration(days: 5));
    
    // Check if delivered to show correct text
    bool isDelivered = displayStatus == 'Delivered';
    String deliveredDateStr = '';
    if (isDelivered && order.timeline.isNotEmpty) {
       final deliveredEvent = order.timeline.lastWhere((e) => e['status'] == 'Delivered', orElse: () => order.timeline.last);
       deliveredDateStr = dateFormat.format(DateTime.parse(deliveredEvent['time']));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID and Date
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order ID: #${order.orderId}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  "${dateFormat.format(order.createdAt)}, ${timeFormat.format(order.createdAt)}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          
          // Store Info and Status
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Store Logo
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _isLoadingStore
                      ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                      : (_store?.logoUrl.isNotEmpty == true
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _store!.logoUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.storefront, color: Colors.grey, size: 20)),
                ),
                const SizedBox(width: 12),
                
                // Store Name & Items count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_store?.name ?? "Loading Store...").replaceAll('_', ' '),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Images + Delivery Info + Total Row
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                // Images Row
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      for (int i = 0; i < order.items.length && i < 2; i++)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: order.items[i].imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey.shade50),
                              errorWidget: (context, url, error) => const Icon(Icons.image, size: 16, color: Colors.grey),
                            ),
                          ),
                        ),
                      if (order.items.length > 2)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5F0), // light warm color
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              "+${order.items.length - 2}",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Delivery Info
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDelivered ? "Delivered on" : "Delivery by",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDelivered ? deliveredDateStr : dateFormat.format(deliveryBy),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Total",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${order.totalAmount.toInt()}",
                      style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Buttons Area
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: Row(
                children: [
                  if (order.orderStatus == 'Delivered' && !order.isRated) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RateProductScreen(order: order),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: AppColors.primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Rate Order",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailsScreen(orderId: order.orderId),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: AppColors.primaryGreen, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        "View Details",
                        style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
