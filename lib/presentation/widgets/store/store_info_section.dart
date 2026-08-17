import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store_model.dart';
import 'store_stats_row.dart';
import 'follow_button.dart';

class StoreInfoSection extends StatelessWidget {
  final StoreModel store;

  const StoreInfoSection({super.key, required this.store});

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)), // Slides up by 20 pixels
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center aligned profile
        children: [
          const SizedBox(height: 12),
          
          // Name and Verified Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  store.name,
                  style: TextStyle(
                    fontSize: 26, // Larger elegant text
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.playfairDisplay().fontFamily, // Matches About Tab
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Store Handle (Slug)
          Text(
            "@${store.storeSlug}",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          
          // Store Subtitle (Location & Category)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _getStoreLocationString(store),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      "${_formatNumber(store.followers)} Followers",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Follow Button
          FollowButton.fromStore(store),
          const SizedBox(height: 12),
        ],
      ),
      ),
    );
  }

  String _getStoreLocationString(StoreModel store) {
    if (store.village.isNotEmpty && store.district.isNotEmpty && store.state.isNotEmpty) {
      return "${store.village}, ${store.district}, ${store.state}";
    }
    if (store.city.isNotEmpty && store.state.isNotEmpty) {
      return "${store.city}, ${store.state}";
    }
    return "Local Homemade";
  }
}
