import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/category_model.dart';

class CategoryHeroCard extends StatelessWidget {
  final CategoryModel category;
  final bool isStoresTab;

  const CategoryHeroCard({
    super.key,
    required this.category,
    required this.isStoresTab,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: isStoresTab ? _buildStoresBanner() : _buildProductsBanner(),
    );
  }

  Widget _buildProductsBanner() {
    return Container(
      key: const ValueKey('products_banner'),
      width: double.infinity,
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF9F5EC),
      ),
      child: Stack(
        children: [
          if (category.imageUrl.isNotEmpty)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  key: ValueKey(category.imageUrl),
                  imageUrl: category.imageUrl,
                  width: 180,
                  memCacheWidth: 400,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Positioned(
            left: 20,
            top: 24,
            bottom: 20,
            right: 180,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Homemade\n${category.name}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E3A2F),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.description.isNotEmpty
                        ? category.description
                        : "Traditional flavors,\nmade with love \u{1F33F}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A5D54),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresBanner() {
    return Container(
      key: const ValueKey('stores_banner'),
      width: double.infinity,
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFEDF4F0),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.storefront,
              size: 160,
              color: AppColors.primaryGreen.withOpacity(0.05),
            ),
          ),
          Positioned(
            left: 20,
            top: 24,
            bottom: 20,
            right: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Discover amazing\nhomemade creators \u{1F497}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A2F),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Support local. Taste real.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A5D54),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
