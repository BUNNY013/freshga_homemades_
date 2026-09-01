import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../providers/customer_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../screens/location_search_screen.dart';
import '../../../presentation/screens/wishlist/liked_products_screen.dart';
import '../../../presentation/screens/notifications/notification_screen.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationSearchScreen()),
              );
            },
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer<CustomerProvider>(
                    builder: (context, customerProvider, child) {
                      final customer = customerProvider.currentCustomer;
                      final city =
                          customer?.city ?? 'home.select_location'.tr();
                      final state = customer?.state ?? '';
                      final displayText = state.isNotEmpty
                          ? '$city, $state'
                          : city;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "home.delivery_to".tr(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayText,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 20),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.currentUser != null
                  ? FirebaseFirestore.instance
                        .collection('customers')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('notifications')
                        .where('isUnread', isEqualTo: true)
                        .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                int unreadCount = snapshot.hasData
                    ? snapshot.data!.docs.length
                    : 0;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.primaryGreen,
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.favorite_border_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LikedProductsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
