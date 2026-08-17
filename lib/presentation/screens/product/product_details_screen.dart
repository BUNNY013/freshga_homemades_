import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../widgets/product/product_image_section.dart';
import '../../widgets/product/variant_selector.dart';
import '../../widgets/product/product_highlights.dart';
import '../../widgets/product/ingredients_section.dart';
import '../../widgets/product/product_info_cards.dart';
import '../../widgets/product/store_products_section.dart';
import '../../widgets/product/rich_store_profile_card.dart';
import '../../widgets/product/similar_products_section.dart';
import '../../widgets/product/suggested_products_section.dart';
import '../../widgets/product/sticky_add_to_cart_bar.dart';
import '../../widgets/product/product_loading_shimmer.dart';
import '../../widgets/cart/floating_cart_bar.dart';
import 'product_ratings_screen.dart';
import '../store/store_screen.dart';
import '../../widgets/modals/report_modal.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isDescriptionExpanded = false;
  final ScrollController _scrollController = ScrollController();
  late ProductProvider _localProvider;

  @override
  void initState() {
    super.initState();
    _localProvider = ProductProvider();
    _localProvider.loadProductDetails(widget.productId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _localProvider.dispose();
    super.dispose();
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          if (hasBadge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '2',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductProvider>.value(
      value: _localProvider,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9F2),
        body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingProduct) {
            return Stack(
              children: [
                const ProductLoadingShimmer(),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: _buildGlassButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            );
          }

          final product = provider.currentProduct;
          if (product == null) {
            return const Center(child: Text("Product not found"));
          }

          final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
          final customerState = customerProvider.currentCustomer?.state;

          final bool isStateRestricted = !product.canSellPanIndia && 
              product.state.isNotEmpty && 
              customerState != null && 
              customerState.isNotEmpty && 
              product.state.toLowerCase() != customerState.toLowerCase();

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: ProductImageSection(product: product),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isStateRestricted) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_off_outlined, color: Colors.orange.shade800, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Not Available in Your State. This product is only available for delivery within ${product.state}.",
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Bestseller
                          if (product.isTrending) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Best Seller",
                                style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          if (!provider.isStoreActive || product.status == 'Unavailable') ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      !provider.isStoreActive 
                                          ? "${product.storeName} is currently on a break and not accepting orders. Please check back later."
                                          : "This product is currently unavailable. Please check back later.",
                                      style: const TextStyle(
                                        color: Color(0xFF991B1B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Title
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

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
                                  "${product.rating.toStringAsFixed(1)} (${product.reviewsCount} reviews)",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Price Area
                          const Text("CURRENT PRICE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${provider.currentVariantPrice.toInt()}",
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                              ),
                              if (provider.currentVariantOriginalPrice > provider.currentVariantPrice) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    "₹${provider.currentVariantOriginalPrice.toInt()}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red.shade100),
                                    ),
                                    child: Text(
                                      "${(((provider.currentVariantOriginalPrice - provider.currentVariantPrice) / provider.currentVariantOriginalPrice) * 100).round()}% OFF",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.red.shade600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text("SELECT WEIGHT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.2)),
                          const SizedBox(height: 8),

                          // Variant Selector
                          const VariantSelector(),
                          const SizedBox(height: 24),

                          // Rich Store Profile Card
                          RichStoreProfileCard(storeId: product.storeId, storeName: product.storeName),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Cream Section (Story, Ingredients, Info)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description (Story Behind)
                          const Text(
                            "About the product",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: LayoutBuilder(
                            builder: (context, constraints) {
                              final span = TextSpan(
                                text: product.description,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.6),
                              );
                              final tp = TextPainter(text: span, textDirection: TextDirection.ltr, maxLines: 5);
                              tp.layout(maxWidth: constraints.maxWidth);
                              final bool exceeded = tp.didExceedMaxLines;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedCrossFade(
                                    firstChild: Text(
                                      product.description,
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.6),
                                    ),
                                    secondChild: Text(
                                      product.description,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.6),
                                    ),
                                    crossFadeState: _isDescriptionExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 200),
                                  ),
                                  if (exceeded) ...[
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
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),

                          // Ingredients
                          IngredientsSection(product: product),
                          const SizedBox(height: 16),
                          
                          // Shelf Life and Dispatch Time
                          ProductInfoCards(product: product),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Store Products
                  const SliverToBoxAdapter(child: StoreProductsSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

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
              const FloatingCartBar(bottomOffset: 80),

              // Sticky Glassy App Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    double offset = 0;
                    if (_scrollController.hasClients) {
                      offset = _scrollController.offset;
                    }
                    // Start fading in at 100px, fully visible at 200px
                    double opacity = ((offset - 100) / 100).clamp(0.0, 1.0);
                    
                    return ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: opacity * 15, sigmaY: opacity * 15),
                        child: Container(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 8,
                            left: 16,
                            right: 16,
                            bottom: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(opacity * 0.85),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200.withOpacity(opacity),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildGlassButton(
                                icon: Icons.arrow_back,
                                onTap: () => Navigator.pop(context),
                              ),
                              // Title fades in
                              Expanded(
                                child: Opacity(
                                  opacity: opacity,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Consumer<WishlistProvider>(
                                    builder: (context, wishlistProvider, _) {
                                      final isWishlisted = wishlistProvider.isLiked(product.id);
                                      return _buildGlassButton(
                                        icon: isWishlisted ? Icons.favorite : Icons.favorite_border,
                                        iconColor: isWishlisted ? Colors.red : Colors.black87,
                                        onTap: () => wishlistProvider.toggleLike(product),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildGlassButton(
                                    icon: Icons.shopping_cart_outlined,
                                    hasBadge: true,
                                    onTap: () {},
                                  ),
                                  const SizedBox(width: 12),
                                  _buildGlassButton(
                                    icon: Icons.share_outlined,
                                    onTap: () {},
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                                    ),
                                    child: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.black87, size: 22),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      position: PopupMenuPosition.under,
                                      elevation: 4,
                                      color: Colors.white,
                                      onSelected: (value) {
                                        if (value == 'report') {
                                          ReportModal.show(
                                            context,
                                            type: 'product_before_order',
                                            targetId: product.id,
                                            targetName: product.name,
                                            storeId: product.storeId,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'report',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.flag_outlined, color: Colors.redAccent, size: 20),
                                              SizedBox(width: 12),
                                              Text('Report Issue', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}
