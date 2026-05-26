import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/category_provider.dart';
import '../../providers/cart_provider.dart';
import '../search/search_screen.dart';
import 'category_discovery_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Usually handled by BottomNav, but if pushed:
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Categories',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                    onPressed: () {},
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          final categories = provider.categories;

          return CustomScrollView(
            slivers: [
              // Subtitle and Count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Shop by the type of homemade goodness',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${categories.length} Categories',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Grid
              if (categories.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "No categories available right now",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75, // Optimized for 3-column
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = categories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryDiscoveryScreen(
                                  category: category,
                                ),
                              ),
                            );
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    child: category.imageUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: category.imageUrl,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(color: Colors.grey.shade100),
                                            errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                          )
                                        : Container(
                                            width: double.infinity,
                                            color: Colors.grey.shade100,
                                            child: const Icon(Icons.category, color: Colors.grey),
                                          ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          category.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12, // Optimized for 3-column
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),

              // Bottom Banner
              if (provider.bannerData != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFE6), // Matches the exact cream color from image
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.bannerData!['title'] ?? "Can't find what you're looking for?",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  provider.bannerData!['subtitle'] ?? "Request a product from your favourite stores.",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    // Handle request product
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(provider.bannerData!['buttonText'] ?? "Request Now"),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (provider.bannerData!['imageUrl'] != null && provider.bannerData!['imageUrl'].toString().isNotEmpty)
                            Expanded(
                              flex: 2,
                              child: CachedNetworkImage(
                                imageUrl: provider.bannerData!['imageUrl'],
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Extra padding for floating cart
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}
