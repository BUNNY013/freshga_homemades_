import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/lottie_constants.dart';
import '../../../providers/customer_provider.dart';
import '../../../models/order_model.dart';
import '../../../models/store_model.dart';
import '../../../services/store_service.dart';
import 'order_details_screen.dart';
import 'rate_product_screen.dart';
import '../store/store_screen.dart';

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          "orders.title".tr(),
          style: const TextStyle(
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

class _OrdersTab extends StatefulWidget {
  final String customerId;

  const _OrdersTab({required this.customerId});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _searchQuery = '';
  List<String> _statusFilter = [];
  final TextEditingController _searchController = TextEditingController();

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<String> availableStatuses = ['New', 'Accepted', 'Packed', 'Shipped', 'Delivered', 'Cancelled'];
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter by Status",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: availableStatuses.map((status) {
                      final isSelected = _statusFilter.contains(status);
                      return FilterChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _statusFilter.add(status);
                            } else {
                              _statusFilter.remove(status);
                            }
                          });
                          setState(() {}); // update parent too
                        },
                        selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                        checkmarkColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryGreen : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search by store or item...",
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _openFilterSheet,
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: _statusFilter.isNotEmpty ? AppColors.primaryGreen : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded, 
                    color: _statusFilter.isNotEmpty ? Colors.white : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        // StreamBuilder List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('customerId', isEqualTo: widget.customerId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                  itemCount: 4,
                  itemBuilder: (context, index) => const _OrderCardSkeleton(),
                );
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

              // Status Filter
              if (_statusFilter.isNotEmpty) {
                // If Cancelled is in filter, we also check for Declined and Auto-Cancelled
                List<String> checkStatuses = List.from(_statusFilter);
                if (checkStatuses.contains('Cancelled')) {
                  checkStatuses.addAll(['Declined', 'Auto-Cancelled']);
                }
                orders = orders.where((o) => checkStatuses.contains(o.orderStatus)).toList();
              }

              // Search Filter
              if (_searchQuery.isNotEmpty) {
                orders = orders.where((o) {
                  final matchesStore = o.storeName.toLowerCase().contains(_searchQuery);
                  final matchesOrderId = o.orderId.toLowerCase().contains(_searchQuery);
                  final matchesItem = o.items.any((item) => item.productName.toLowerCase().contains(_searchQuery));
                  return matchesStore || matchesOrderId || matchesItem;
                }).toList();
              }

              if (orders.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                color: AppColors.primaryGreen,
                onRefresh: () async {
                  // Since we are using a StreamBuilder, the data is already real-time.
                  // We add a slight delay to give the user visual feedback of a refresh.
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return _OrderCard(order: orders[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            LottieConstants.emptyOrders,
            height: 180,
            repeat: true,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 50,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No orders found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "We couldn't find any orders matching\nyour criteria.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 2.5), // Thick beautiful border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(orderId: order.orderId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Store Logo + Name + Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_store != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoreScreen(storeId: _store!.id), // assuming store has id
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryGreen.withOpacity(0.15), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: _isLoadingStore
                                ? const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))
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
                        ],
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_store != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreScreen(storeId: _store!.id),
                              ),
                            );
                          }
                        },
                        child: Text(
                          (_store?.name ?? "Loading Store...").replaceAll('_', ' '),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                const SizedBox(height: 16),
                
                // Items Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 2.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.items.map((e) => "${e.productName} x${e.quantity}").join(', '),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryGreen, size: 18),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Date & Total Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivered ? "Delivered on" : "Placed on",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDelivered ? deliveredDateStr : "${dateFormat.format(order.createdAt)}, ${timeFormat.format(order.createdAt)}",
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${order.totalAmount.toInt()}",
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Rate Stars (if delivered and not rated)
                if (order.orderStatus == 'Delivered' && !order.isRated) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Rate your order: ",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RateProductScreen(order: order),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Icon(
                                Icons.star_border_rounded,
                                color: AppColors.primaryGreen,
                                size: 28,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Container(width: 120, height: 16, color: Colors.grey.shade200),
              const Spacer(),
              Container(width: 60, height: 20, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
            ],
          ),
          const SizedBox(height: 16),
          Container(width: double.infinity, height: 14, color: Colors.grey.shade200),
          const SizedBox(height: 6),
          Container(width: 180, height: 14, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 70, height: 12, color: Colors.grey.shade200),
                  const SizedBox(height: 4),
                  Container(width: 100, height: 14, color: Colors.grey.shade200),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: 70, height: 12, color: Colors.grey.shade200),
                  const SizedBox(height: 4),
                  Container(width: 60, height: 16, color: Colors.grey.shade200),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
