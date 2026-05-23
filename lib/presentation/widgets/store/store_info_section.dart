import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store_model.dart';
import 'store_stats_row.dart';
import 'follow_button.dart';

class StoreInfoSection extends StatelessWidget {
  final StoreModel store;

  const StoreInfoSection({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo overlapping banner
          Transform.translate(
            offset: const Offset(0, -30),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: store.logoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade100),
                  errorWidget: (context, url, error) => const Icon(Icons.store, color: Colors.grey),
                ),
              ),
            ),
          ),
          
          // Name and Follow Row
          Transform.translate(
            offset: const Offset(0, -10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (store.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: Icon(Icons.verified, color: AppColors.primaryGreen, size: 20),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const FollowButton(),
              ],
            ),
          ),
          
          // Stats Row
          StoreStatsRow(store: store),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
