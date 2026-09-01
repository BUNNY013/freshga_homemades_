import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order_model.dart';
import '../../../models/store_model.dart';
import '../../../services/store_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  StoreModel? _store;
  bool _isLoadingStore = true;

  final List<String> _expectedTimeline = [
    'Order Placed',
    'Confirmed by Store',
    'Packed',
    'Shipped',
    'Delivered',
  ];

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

  Map<String, dynamic>? _getTimelineDataForStep(
    OrderModel order,
    String expectedStep,
  ) {
    // Map our UI expected steps to the backend status string
    String statusToCheck = expectedStep;
    if (expectedStep == 'Order Placed') statusToCheck = 'New';
    if (expectedStep == 'Confirmed by Store') statusToCheck = 'Accepted';

    // Check in timeline array first
    for (var event in order.timeline) {
      if (event['status'] == statusToCheck) {
        return event;
      }
    }

    // For 'New'/'Order Placed', if not in timeline, fallback to order.createdAt
    if (statusToCheck == 'New') {
      return {'status': 'New', 'time': order.createdAt.toIso8601String()};
    }

    return null;
  }

  bool _isStepCompleted(OrderModel order, String expectedStep) {
    return _getTimelineDataForStep(order, expectedStep) != null;
  }

  bool _isOrderCancelled(OrderModel order) {
    return [
      'Declined',
      'Cancelled',
      'Auto-Cancelled',
    ].contains(order.orderStatus);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.orderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Something went wrong")),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Order not found")));
        }

        final orderData = snapshot.data!.data() as Map<String, dynamic>;
        final order = OrderModel.fromJson(orderData);
        final shippingDetails =
            orderData['shippingDetails'] as Map<String, dynamic>?;

        final dateFormat = DateFormat('dd MMM, yyyy');
        final timeFormat = DateFormat('hh:mm a');
        final estimatedDelivery = order.maxDispatchDate.add(
          const Duration(days: 5),
        );

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
              "Track Order",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {},
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
                // Estimated Delivery Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Estimated Delivery",
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(estimatedDelivery),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.delivery_dining,
                        size: 48,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Order Summary
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
                      Text(
                        "Order ID: ${order.orderId}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _store?.name ?? "Loading Store...",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${order.items.length} items • ₹${order.totalAmount.toInt()}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context); // Go back to details
                            },
                            child: const Text(
                              "View Details >",
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Cancellation Warning
                if (_isOrderCancelled(order)) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "This order was cancelled (${order.orderStatus}). Tracking is no longer available.",
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Timeline
                if (!_isOrderCancelled(order))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: List.generate(_expectedTimeline.length, (
                        index,
                      ) {
                        final stepTitle = _expectedTimeline[index];
                        final timelineEvent = _getTimelineDataForStep(
                          order,
                          stepTitle,
                        );
                        final isCompleted = timelineEvent != null;

                        bool isLast = index == _expectedTimeline.length - 1;

                        return _buildTimelineStep(
                          title: stepTitle,
                          date: isCompleted
                              ? dateFormat.format(
                                  DateTime.parse(timelineEvent['time']),
                                )
                              : '',
                          time: isCompleted
                              ? timeFormat.format(
                                  DateTime.parse(timelineEvent['time']),
                                )
                              : '',
                          note: isCompleted && timelineEvent['note'] != null
                              ? timelineEvent['note']
                              : '',
                          isCompleted: isCompleted,
                          isLast: isLast,
                        );
                      }),
                    ),
                  ),

                const SizedBox(height: 24),

                // Delivery Partner Details (if shipped)
                if ((shippingDetails != null ||
                        order.shippingProvider.isNotEmpty) &&
                    !_isOrderCancelled(order)) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shippingDetails?['shippingMethod'] ==
                                            'Self Delivery'
                                        ? 'Delivery via'
                                        : "Delivery Partner",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    shippingDetails?['shippingMethod'] ==
                                            'Self Delivery'
                                        ? 'Vendor Direct Delivery'
                                        : (shippingDetails?['shippingProvider'] ??
                                              order.shippingProvider),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),

                                  if (shippingDetails != null &&
                                      shippingDetails['trackingId'] != null &&
                                      shippingDetails['trackingId']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Tracking ID: ${shippingDetails['trackingId']}",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ] else if (order.trackingId.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Tracking ID: ${order.trackingId}",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],

                                  if (shippingDetails != null &&
                                      shippingDetails['receiptNumber'] !=
                                          null &&
                                      shippingDetails['receiptNumber']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "LR/Receipt No: ${shippingDetails['receiptNumber']}",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],

                                  if (shippingDetails != null &&
                                      shippingDetails['deliveryTime'] != null &&
                                      shippingDetails['deliveryTime']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Expected Time: ${shippingDetails['deliveryTime']}",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if ((shippingDetails?['trackingLink'] != null &&
                                    shippingDetails!['trackingLink']
                                        .toString()
                                        .isNotEmpty) ||
                                order.trackingLink.isNotEmpty)
                              IconButton(
                                onPressed: () async {
                                  final link =
                                      shippingDetails?['trackingLink']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true
                                      ? shippingDetails!['trackingLink']
                                      : order.trackingLink;
                                  final uri = Uri.parse(link);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                                icon: const Icon(
                                  Icons.open_in_new,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            if (shippingDetails != null &&
                                shippingDetails['contactNumber'] != null &&
                                shippingDetails['contactNumber']
                                    .toString()
                                    .isNotEmpty)
                              IconButton(
                                onPressed: () async {
                                  final uri = Uri.parse(
                                    'tel:${shippingDetails['contactNumber']}',
                                  );
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                                icon: const Icon(
                                  Icons.call,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                          ],
                        ),
                        if (shippingDetails != null &&
                            shippingDetails['receiptImageUrl'] != null &&
                            shippingDetails['receiptImageUrl']
                                .toString()
                                .isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (c) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(16),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      InteractiveViewer(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                shippingDetails['receiptImageUrl'],
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(
                                                  color: AppColors.primaryGreen,
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white,
                                                      size: 50,
                                                    ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -24,
                                        right: -24,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                          onPressed: () => Navigator.pop(c),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  color: AppColors.primaryGreen,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "View Dispatch Receipt / Photo",
                                  style: TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String date,
    required String time,
    required String note,
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
                color: isCompleted
                    ? AppColors.primaryGreen
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : const Icon(Icons.circle, size: 8, color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted
                    ? AppColors.primaryGreen
                    : Colors.grey.shade200,
              ),
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
                    color: isCompleted ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                if (isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    "$date • $time",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
                if (isCompleted && note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
