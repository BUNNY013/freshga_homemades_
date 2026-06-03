import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/following_provider.dart';
import '../../presentation/screens/store/store_screen.dart';
import '../../presentation/screens/following/all_followed_stores_screen.dart';
import 'section_title.dart';

class FollowingStoresSection extends StatelessWidget {
  final String title;

  const FollowingStoresSection({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingIds) {
          return const SizedBox(); // Could show shimmer here
        }

        if (provider.followingStoresData.isEmpty) {
          return const SizedBox(); // Hide completely if not following anyone
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: title,
              onSeeAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AllFollowedStoresScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110, // Height for circular avatar + text
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: provider.followingStoresData.length,
                itemBuilder: (context, index) {
                  final store = provider.followingStoresData[index];
                  return _buildFollowingStore(context, store);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFollowingStore(BuildContext context, Map<String, dynamic> storeData) {
    final String storeId = storeData['storeId'] ?? '';
    final String storeName = storeData['storeName'] ?? 'Store';
    final String storeLogo = storeData['storeLogo'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreScreen(storeId: storeId),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGreen, width: 2), // Ring like Instagram stories
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: storeLogo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: storeLogo,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey.shade200),
                          errorWidget: (context, url, error) => const Icon(Icons.store, color: Colors.grey),
                        )
                      : const Icon(Icons.store, size: 30, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              storeName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
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
  }
}
