import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/product/product_image_section.dart';
import '../../widgets/product/variant_selector.dart';
import '../../widgets/product/product_highlights.dart';
import '../../widgets/product/ingredients_section.dart';
import '../../widgets/product/similar_products_section.dart';
import '../../widgets/product/suggested_products_section.dart';
import '../../widgets/product/sticky_add_to_cart_bar.dart';
import '../../widgets/product/product_loading_shimmer.dart';
import '../../widgets/cart/floating_cart_bar.dart';
import 'product_ratings_screen.dart';
import '../store/store_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProductDetails(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingProduct) {
            return const ProductLoadingShimmer();
          }

          final product = provider.currentProduct;
          if (product == null) {
            return const Center(child: Text("Product not found"));
          }

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: ProductImageSection(product: product),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Bestseller Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              if (product.isTrending) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        "Bestseller",
                                        style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Store Info Link
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => StoreScreen(storeId: product.storeId)));
                            },
                            child: Row(
                              children: [
                                Text(
                                  "By ${product.storeName}",
                                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: AppColors.primaryGreen, size: 16),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Ratings
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ProductRatingsScreen(product: product)));
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "(${product.reviewsCount} ratings)",
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Price Area
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "₹${provider.currentVariantPrice.toInt()}",
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                              ),
                              if (provider.currentVariantOriginalPrice > provider.currentVariantPrice) ...[
                                const SizedBox(width: 8),
                                Text(
                                  "₹${provider.currentVariantOriginalPrice.toInt()}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (provider.variants.isNotEmpty && provider.selectedVariantIndex < provider.variants.length)
                            Text(
                              "${provider.variants[provider.selectedVariantIndex].label} (₹${(provider.currentVariantPrice / 2.5).toStringAsFixed(1)} / 100g)",
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          const SizedBox(height: 24),

                          // Highlights
                          ProductHighlights(product: product),
                          const SizedBox(height: 32),

                          // Description
                          const Text(
                            "About this product",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          AnimatedCrossFade(
                            firstChild: Text(
                              product.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                            ),
                            secondChild: Text(
                              product.description,
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                            ),
                            crossFadeState: _isDescriptionExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isDescriptionExpanded = !_isDescriptionExpanded;
                              });
                            },
                            child: Text(
                              _isDescriptionExpanded ? "Read Less" : "Read More",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Variant Selector
                          const VariantSelector(),
                          const SizedBox(height: 32),

                          // Ingredients
                          IngredientsSection(product: product),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  
                  // Similar Products
                  const SliverToBoxAdapter(child: SimilarProductsSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  
                  // Suggested Products
                  const SliverToBoxAdapter(child: SuggestedProductsSection()),
                  
                  // Bottom spacing for sticky bar
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              
              // Bottom Sticky Bar
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: StickyAddToCartBar(),
              ),

              // Floating Cart Bar (Above sticky bar)
              const FloatingCartBar(bottomOffset: 80), // 80 is the height of sticky bar
            ],
          );
        },
      ),
    );
  }
}
