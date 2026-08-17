import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isUnread;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isUnread = false,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: "Order Delivered!",
      message: "Your order #8902 has been delivered successfully. Enjoy your homemade treats!",
      time: "2 mins ago",
      icon: Icons.local_shipping_rounded,
      iconColor: AppColors.primaryGreen,
      isUnread: true,
    ),
    NotificationItem(
      title: "Grandma's Pickles",
      message: "A store you follow just added a new product: Spicy Mango Pickle.",
      time: "1 hour ago",
      icon: Icons.storefront_rounded,
      iconColor: AppColors.goldenYellow,
      isUnread: true,
    ),
    NotificationItem(
      title: "Items in your cart",
      message: "You left items in your cart. Checkout now to support local makers!",
      time: "5 hours ago",
      icon: Icons.shopping_bag_rounded,
      iconColor: AppColors.textSecondary,
      isUnread: false,
    ),
    NotificationItem(
      title: "Order Confirmed",
      message: "Your order #8902 has been confirmed by the vendor.",
      time: "Yesterday",
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.primaryGreen,
      isUnread: false,
    ),
    NotificationItem(
      title: "System Update",
      message: "Freshga app has been updated with new performance improvements.",
      time: "2 days ago",
      icon: Icons.system_update_rounded,
      iconColor: Colors.blueAccent,
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _notifications.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 400)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Handle tap
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon Container
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: notification.iconColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    notification.icon,
                                    color: notification.iconColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification.title,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            notification.time,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                            notification.message,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: notification.isUnread ? AppColors.textPrimary.withOpacity(0.9) : AppColors.textSecondary,
                                              height: 1.4,
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                                
                                // Unread Dot
                                if (notification.isUnread)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0, top: 4),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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
