import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/store_model.dart';
import '../../presentation/screens/store/store_screen.dart';
import '../../presentation/widgets/store/follow_button.dart';
import 'loading_shimmers.dart';

class StoreCard extends StatelessWidget {
  final StoreModel store;
  final bool isFullWidth;

  const StoreCard({super.key, required this.store, this.isFullWidth = false});

  String _formatFollowers(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreScreen(storeId: store.id),
          ),
        );
      },
      child: Container(
        width: isFullWidth ? double.infinity : 250, // Expand if full width
        margin: EdgeInsets.symmetric(
          horizontal: isFullWidth ? 16 : 8,
          vertical: isFullWidth ? 8 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Banner + Logo Stack
            SizedBox(
              height: isFullWidth
                  ? 150
                  : 110, // Taller stack to accommodate larger logo
              child: Stack(
                children: [
                  // Banner Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: store.bannerUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: store.bannerUrl,
                            height: isFullWidth ? 110 : 85,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ShimmerLoading(
                              width: double.infinity,
                              height: isFullWidth ? 110 : 85,
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: isFullWidth ? 110 : 85,
                              color: Colors.grey.shade200,
                            ),
                          )
                        : Container(
                            height: isFullWidth ? 110 : 85,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                          ),
                  ),

                  // Gradient Overlay
                  Container(
                    height: isFullWidth ? 110 : 85,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),

                  // Overlapping Logo
                  Positioned(
                    left: isFullWidth ? 20 : 12,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: isFullWidth ? 38 : 26,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: store.logoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(store.logoUrl)
                            : null,
                        child: store.logoUrl.isEmpty
                            ? Icon(
                                Icons.store,
                                color: Colors.grey,
                                size: isFullWidth ? 32 : 20,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Store Details
            Padding(
              padding: EdgeInsets.fromLTRB(
                isFullWidth ? 20 : 12,
                isFullWidth ? 12 : 10,
                isFullWidth ? 20 : 12,
                isFullWidth ? 20 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Name (No verified badge)
                  Text(
                    store.name,
                    style: TextStyle(
                      fontSize: isFullWidth ? 18 : 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (store.reviewsCount > 0) ...[
                    const SizedBox(height: 4),

                    // Rating Row
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Followers & Follow Button Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "${_formatFollowers(store.followers)} Followers",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      FollowButton.fromStore(
                        store,
                        isCompact: false,
                        showNotificationBell: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
