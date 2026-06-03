import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/following_provider.dart';
import '../../../models/store_update_model.dart';
import '../../presentation/screens/store/store_screen.dart';
import '../../presentation/screens/following/following_screen.dart';
import '../../screens/customer_home_screen.dart';
import 'section_title.dart';

class StoreUpdatesSection extends StatelessWidget {
  final String title;

  const StoreUpdatesSection({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SizedBox(); 
        }

        if (provider.feed.isEmpty) {
          return const SizedBox(); 
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: title,
              onSeeAll: () {
                // Switch to the Following Tab (Index 2)
                CustomerHomeScreen.globalKey.currentState?.switchTab(2);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220, 
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: provider.feed.length > 5 ? 5 : provider.feed.length, // Limit to 5 on home feed
                itemBuilder: (context, index) {
                  final update = provider.feed[index];
                  return _buildUpdateCard(context, update);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpdateCard(BuildContext context, StoreUpdateModel update) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreScreen(storeId: update.storeId),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: update.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: update.imageUrl,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(height: 100, color: Colors.grey.shade200),
                          errorWidget: (context, url, error) => Container(height: 100, color: Colors.grey.shade200),
                        )
                      : Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                        ),
                ),
                // Badge
                if (update.badgeText.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(update.type),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        update.badgeText.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: update.storeLogo.isNotEmpty ? CachedNetworkImageProvider(update.storeLogo) : null,
                        child: update.storeLogo.isEmpty ? const Icon(Icons.store, size: 8, color: Colors.grey) : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          update.storeName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    update.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    update.ctaText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(String type) {
    switch (type) {
      case 'new_launch':
        return AppColors.terracotta;
      case 'restock':
        return AppColors.primaryGreen;
      case 'offer':
        return Colors.orange.shade700;
      default:
        return AppColors.textPrimary;
    }
  }
}
