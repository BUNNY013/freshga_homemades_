import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/store_model.dart';
import '../../presentation/screens/store/store_screen.dart';
import 'loading_shimmers.dart';

class StoreCard extends StatelessWidget {
  final StoreModel store;

  const StoreCard({super.key, required this.store});

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
          MaterialPageRoute(builder: (context) => StoreScreen(storeId: store.id)),
        );
      },
      child: Container(
        width: 200, // Increased width for a wider, rectangular store feel
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
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banner
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: store.bannerUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: store.bannerUrl,
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerLoading(width: double.infinity, height: 90),
                        errorWidget: (context, url, error) => Container(height: 90, color: Colors.grey.shade200),
                      )
                    : Container(
                        height: 90,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                      ),
              ),
              // Space for overlapping logo
              const SizedBox(height: 28),
              
              // Store Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Followers
                        Expanded(
                          child: Text(
                            "${_formatFollowers(store.followers)} Followers",
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Follow Button
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1E7036)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Follow",
                            style: TextStyle(color: Color(0xFF1E7036), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
          
          // Overlapping Logo
          Positioned(
            left: 12,
            top: 90 - 22, // Banner height - logo radius
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: store.logoUrl.isNotEmpty ? CachedNetworkImageProvider(store.logoUrl) : null,
                child: store.logoUrl.isEmpty ? const Icon(Icons.store, color: Colors.grey, size: 20) : null,
              ),
            ),
          ),
          
          // Heart Icon overlay
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border, size: 14, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    ));
  }
}
