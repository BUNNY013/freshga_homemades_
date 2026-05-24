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
          // The logo is now rendered by StoreHeader to properly overlap the banner without clipping.
          // We add a tiny bit of spacing to balance the layout.
          const SizedBox(height: 8),
          
          // Name and Follow Row
          Row(
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
              const FollowButton(), // Using the green filled FollowButton
            ],
          ),
          
          // Stats Row
          StoreStatsRow(store: store),
          const SizedBox(height: 16),
          
          // Divider
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          
          // Info Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoBadge(Icons.eco_outlined, "100% Natural", "No preservatives"),
              _buildInfoBadge(Icons.access_time_outlined, store.dispatchTime, "Dispatch Time"),
              _buildInfoBadge(Icons.location_on_outlined, "Bangalore,", "Karnataka"),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        )
      ],
    );
  }
}
