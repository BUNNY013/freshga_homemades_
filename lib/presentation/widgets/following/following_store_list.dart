import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/following_provider.dart';
import '../../screens/store/store_screen.dart';
import '../../screens/following/all_followed_stores_screen.dart';

class FollowingStoreList extends StatelessWidget {
  const FollowingStoreList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowingProvider>(
      builder: (context, provider, child) {
        final stores = provider.followingStoresData;

        if (provider.isLoadingIds) {
          return _buildSkeleton();
        }

        if (stores.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Following Stores',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllFollowedStoresScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: stores.length,
                itemBuilder: (context, index) {
                  final store = stores[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StoreScreen(storeId: store['storeId']),
                        ),
                      );
                    },
                    child: Container(
                      width: 72,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage:
                                (store['storeLogo'] != null &&
                                    store['storeLogo'].toString().isNotEmpty)
                                ? CachedNetworkImageProvider(store['storeLogo'])
                                : null,
                            child:
                                (store['storeLogo'] == null ||
                                    store['storeLogo'].toString().isEmpty)
                                ? Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.textSecondary,
                                    size: 24,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            store['storeName'] ?? 'Store',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ],
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 140, height: 20, color: Colors.grey.shade200),
              Container(width: 60, height: 16, color: Colors.grey.shade200),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 72,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 40,
                      height: 10,
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
