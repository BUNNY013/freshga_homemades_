import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store_model.dart';
import '../../../models/product_model.dart';
import '../../../services/store_service.dart';
import '../../../presentation/widgets/store/follow_button.dart';
import '../../../presentation/screens/store/store_screen.dart';

class DiscoveryStoreCard extends StatelessWidget {
  final StoreModel store;

  const DiscoveryStoreCard({super.key, required this.store});

  String _formatFollowers(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                    image: store.logoUrl.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(store.logoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: store.logoUrl.isEmpty ? const Icon(Icons.store, color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                // Store Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              store.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (store.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.verified, color: AppColors.primaryGreen, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.goldenYellow),
                          const SizedBox(width: 4),
                          Text(
                            "${store.rating} (${store.reviewsCount})",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const Text(" • ", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            "${_formatFollowers(store.followers)} Followers",
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        store.description.isNotEmpty ? store.description : "Traditional recipes made with natural ingredients.",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Follow Button
                FollowButton.fromStore(store, isCompact: true),
              ],
            ),
            const SizedBox(height: 16),
            // Tags
            if (store.categories.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                children: store.categories.take(3).map((tag) => Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // 3 Preview Products
            FutureBuilder<List<ProductModel>>(
              future: StoreService().getStoreProducts(store.storeId.isNotEmpty ? store.storeId : store.id, limit: 3),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox();
                }
                final products = snapshot.data!;
                return Row(
                  children: products.map((p) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: p == products.last ? 0 : 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: p.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: p.imageUrl,
                                height: 70,
                                fit: BoxFit.cover,
                              )
                            : Container(height: 70, color: Colors.grey.shade200),
                      ),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
