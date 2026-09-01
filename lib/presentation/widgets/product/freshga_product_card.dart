import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../screens/product/product_details_screen.dart';
import '../store/variant_selection_bottom_sheet.dart';

class FreshgaProductCard extends StatefulWidget {
  final ProductModel product;
  final double? width;

  const FreshgaProductCard({super.key, required this.product, this.width});

  @override
  State<FreshgaProductCard> createState() => _FreshgaProductCardState();
}

class _FreshgaProductCardState extends State<FreshgaProductCard> {
  bool _isAdding = false;
  bool _isPressed = false;

  void _toggleWishlist() {
    context.read<WishlistProvider>().toggleLike(widget.product);
  }

  void _addToCart() async {
    if (widget.product.variants.isEmpty) return;

    if (widget.product.variants.length > 1) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => VariantSelectionBottomSheet(product: widget.product),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final error = await context.read<CartProvider>().addToCart(
        product: widget.product,
        variant: widget.product.variants.first,
      );
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${widget.product.name} added to cart",
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMultipleVariants = widget.product.variants.length > 1;
    final bool isOutOfStock =
        widget.product.variants.isNotEmpty &&
        widget.product.variants.first.isOutOfStock;
    final bool hasReviews = widget.product.reviewsCount > 0;

    final bool hasDiscount =
        widget.product.originalPrice > widget.product.price;
    final int discountPercentage = hasDiscount
        ? (((widget.product.originalPrice - widget.product.price) /
                      widget.product.originalPrice) *
                  100)
              .round()
        : 0;

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailsScreen(productId: widget.product.id),
            ),
          );
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.grey.shade50, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── IMAGE SECTION (flexible to prevent overflow) ───────────────
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: widget.product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.product.imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey.shade100),
                              errorWidget: (context, url, error) =>
                                  Container(color: Colors.grey.shade100),
                            )
                          : Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey.shade100,
                            ),
                    ),

                    // Wishlist button (top-right)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Consumer<WishlistProvider>(
                        builder: (context, wishlistProvider, _) {
                          final isWishlisted = wishlistProvider.isLiked(
                            widget.product.id,
                          );
                          return GestureDetector(
                            onTap: _toggleWishlist,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                child: Icon(
                                  isWishlisted
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  key: ValueKey<bool>(isWishlisted),
                                  size: 22,
                                  color: isWishlisted
                                      ? Colors.red
                                      : Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
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
                ),
              ),

              // ─── CONTENT SECTION (Expanded — fills remaining card space) ──
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product name
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Store name
                      Row(
                        children: [
                          const Text(
                            "By ",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.product.storeName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.product.isStoreVerified) ...[
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.verified,
                              size: 13,
                              color: AppColors.primaryGreen,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Rating + weight meta row
                      Row(
                        children: [
                          if (hasReviews) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: AppColors.goldenYellow,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "${widget.product.rating}",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "(${widget.product.reviewsCount})",
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (widget.product.weight.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.0),
                              child: Text(
                                "|",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.product.weight,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Price block
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              "₹${widget.product.price.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryGreen,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 4),
                            Text(
                              "₹${widget.product.originalPrice.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (hasDiscount && discountPercentage > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Text(
                            "$discountPercentage% OFF",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),

                      // Variants chip and Add Button Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Variants chip
                          if (hasMultipleVariants)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(
                                    0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 11,
                                      color: AppColors.primaryGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        "${widget.product.variants.length} sizes",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGreen,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const SizedBox(), // Empty space if no variants
                          // Light Theme Add Button
                          GestureDetector(
                            onTap: isOutOfStock ? null : _addToCart,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isOutOfStock
                                    ? Colors.grey.shade100
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isOutOfStock
                                      ? Colors.grey.shade300
                                      : AppColors.primaryGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGreen.withOpacity(
                                      0.05,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _isAdding
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryGreen,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      isOutOfStock ? "SOLD OUT" : "ADD",
                                      style: TextStyle(
                                        color: isOutOfStock
                                            ? Colors.grey.shade500
                                            : AppColors.primaryGreen,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
