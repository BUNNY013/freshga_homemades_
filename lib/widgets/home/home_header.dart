import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';

import '../../../providers/customer_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../screens/location_search_screen.dart';
import '../../../presentation/screens/wishlist/liked_products_screen.dart';

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
                const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer<CustomerProvider>(
                    builder: (context, customerProvider, child) {
                      final customer = customerProvider.currentCustomer;
                      final city = customer?.city ?? 'Select Location';
                      final state = customer?.state ?? '';
                      final displayText = state.isNotEmpty ? '$city, $state' : city;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Delivery to",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayText,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 20),
                            ],
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Consumer<WishlistProvider>(
              builder: (context, wishlistProvider, _) {
                final count = wishlistProvider.likedProducts.length;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border_rounded, color: AppColors.textPrimary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LikedProductsScreen()),
                        );
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}
