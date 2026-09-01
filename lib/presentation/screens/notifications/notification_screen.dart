import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/notification_model.dart';
import '../orders/order_details_screen.dart';
import '../product/product_details_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _isPermissionDenied = status.isDenied || status.isPermanentlyDenied;
    });
  }

  Future<void> _requestPermission() async {
    await openAppSettings();
  }

  String get _formatTime {
    return "Just now"; // A simple helper could be added for timeago, but we'll use a basic format for now
  }

  String _timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return "${(diff.inDays / 365).floor()}y";
    if (diff.inDays > 7) return "${(diff.inDays / 7).floor()}w";
    if (diff.inDays > 1) return "${diff.inDays}d";
    if (diff.inDays == 1) return "1d";
    if (diff.inHours > 0) return "${diff.inHours}h";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "Now";
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'order_update':
        return Icons.local_shipping_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'order_update':
        return AppColors.primaryGreen;
      case 'promo':
        return AppColors.goldenYellow;
      default:
        return Colors.blueAccent;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isUnread': false});
    }
  }

  Future<void> _markAllAsRead() async {
    final user = _auth.currentUser;
    if (user != null) {
      final unreadDocs = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('notifications')
          .where('isUnread', isEqualTo: true)
          .get();

      if (unreadDocs.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in unreadDocs.docs) {
          batch.update(doc.reference, {'isUnread': false});
        }
        await batch.commit();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: user != null
                ? _firestore
                      .collection('customers')
                      .doc(user.uid)
                      .collection('notifications')
                      .where('isUnread', isEqualTo: true)
                      .limit(1)
                      .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              final hasUnread =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return TextButton(
                onPressed: hasUnread ? _markAllAsRead : null,
                child: Text(
                  "Mark all read",
                  style: TextStyle(
                    color: hasUnread
                        ? AppColors.primaryGreen
                        : Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: user == null
          ? _buildEmptyState()
          : Column(
              children: [
                if (_isPermissionDenied)
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_off_rounded,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Turn on notifications",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Don't miss updates on your orders and favorite stores.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _requestPermission,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Enable"),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('customers')
                        .doc(user.uid)
                        .collection('notifications')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      final notifications = snapshot.data!.docs
                          .map((doc) => NotificationModel.fromFirestore(doc))
                          .toList();

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: notifications.length,
                        physics: const BouncingScrollPhysics(),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _markAsRead(notification.id);
                              if (notification.type == 'order_update' &&
                                  notification.orderId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailsScreen(
                                      orderId: notification.orderId!,
                                    ),
                                  ),
                                );
                              } else if (notification.type == 'promo' &&
                                  notification.productId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsScreen(
                                      productId: notification.productId!,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: notification.isUnread
                                    ? AppColors.primaryGreen.withOpacity(0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: notification.isUnread
                                      ? AppColors.primaryGreen.withOpacity(0.3)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Larger Icon Container or Image
                                  if (notification.imageUrl != null &&
                                      notification.imageUrl!.isNotEmpty)
                                    Container(
                                      height: 52,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            notification.imageUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 52,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        color: _getColorForType(
                                          notification.type,
                                        ).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getIconForType(notification.type),
                                        color: _getColorForType(
                                          notification.type,
                                        ),
                                        size: 26,
                                      ),
                                    ),
                                  const SizedBox(width: 16),

                                  // Separated Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notification.title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      notification.isUnread
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Row(
                                              children: [
                                                Text(
                                                  _timeAgo(
                                                    notification.createdAt,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        notification.isUnread
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                    color: notification.isUnread
                                                        ? AppColors.primaryGreen
                                                        : Colors.grey.shade500,
                                                  ),
                                                ),
                                                if (notification.isUnread) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: AppColors
                                                              .primaryGreen,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          notification.message,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: notification.isUnread
                                                ? AppColors.textPrimary
                                                      .withOpacity(0.9)
                                                : AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Notifications Yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "When you get updates about your orders\nor followed stores, they'll show up here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
