import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../screens/product/product_details_screen.dart';
import 'variant_selection_bottom_sheet.dart';

class StoreProductListItem extends StatefulWidget {
  final ProductModel product;

  const StoreProductListItem({super.key, required this.product});

  @override
  State<StoreProductListItem> createState() => _StoreProductListItemState();
}

class _StoreProductListItemState extends State<StoreProductListItem> {
  bool _isAdding = false;

  void _addToCart() async {
    if (widget.product.variants.isEmpty) return;
    
    // If multiple variants exist, slide up the Choose Size bottom sheet
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
      await Future.delayed(const Duration(milliseconds: 300));
      context.read<CartProvider>().addToCart(
        product: widget.product,
        variant: widget.product.variants.first,
      );
      if (mounted) {
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
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    
    final bool isStoreActive = (storeProvider.currentStore?.isActive ?? true) &&
        !(storeProvider.currentStore?.isSuspended ?? false) && storeProvider.isStoreActive;
    final store = storeProvider.currentStore;
    final customerState = customerProvider.currentCustomer?.state;
    
    final bool isStateRestricted = store != null && 
        !store.canSellPanIndia && 
        store.state.isNotEmpty && 
        customerState != null && 
        customerState.isNotEmpty && 
        store.state.toLowerCase() != customerState.toLowerCase();
    
    
    final bool hasMultipleVariants = widget.product.variants.length > 1;
    final bool isOutOfStock = widget.product.variants.isNotEmpty && !widget.product.variants.first.inStock;
    final bool hasDiscount = widget.product.originalPrice > widget.product.price;
    final bool isProductUnavailable = widget.product.status == 'Unavailable';
    final int discountPercentage = hasDiscount
        ? (((widget.product.originalPrice - widget.product.price) / widget.product.originalPrice) * 100).round()
        : 0;
        
    final String sizeLabel = widget.product.variants.isNotEmpty ? widget.product.variants.first.label : widget.product.weight;

    return GestureDetector(
      onTap: (!isStoreActive || isProductUnavailable || isStateRestricted) ? () {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(isStateRestricted 
                ? "This product is not deliverable to your state."
                : (!isStoreActive 
                    ? "This store is currently on a break and not accepting orders."
                    : "This product is currently unavailable.")),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(productId: widget.product.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Content: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Veg/Non-Veg Tag & Rating
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: widget.product.tags.contains('Vegan') || widget.product.tags.contains('Vegetarian') || widget.product.tags.contains('Veg')
                                ? Colors.green 
                                : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: widget.product.tags.contains('Vegan') || widget.product.tags.contains('Vegetarian') || widget.product.tags.contains('Veg')
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                      if (widget.product.tags.contains("Bestseller")) ...[
                        const SizedBox(width: 8),
                        const Text(
                          "Bestseller",
                          style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                      if (widget.product.rating > 0) ...[
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Quantity / Size
                  Text(
                    hasMultipleVariants 
                        ? "Starts from ${widget.product.variants.first.label}" 
                        : (widget.product.variants.isNotEmpty ? widget.product.variants.first.label : widget.product.weight),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Pricing Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "₹${widget.product.price.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryGreen,
                          letterSpacing: -1,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              "₹${widget.product.originalPrice.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8), // Premium slate grey
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0E5), // Soft pastel orange
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$discountPercentage% OFF",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF97316), // Premium vibrant orange
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Right Content: Image & Add Button
            SizedBox(
              width: 160,
              height: 184,
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.imageUrl.isNotEmpty ? widget.product.imageUrl : '',
                      height: 160,
                      width: 160,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade100),
                      errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                    ),
                  ),

                  // Add Button (Light Theme)
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 110,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: (isOutOfStock || !isStoreActive || isProductUnavailable || isStateRestricted) ? null : _addToCart,
                          child: Center(
                            child: _isAdding
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isStateRestricted 
                                            ? "UNAVAILABLE" 
                                            : (!isStoreActive 
                                                ? "PAUSED" 
                                                : (isProductUnavailable ? "UNAVAILABLE" : (isOutOfStock ? "SOLD OUT" : "ADD"))),
                                        style: TextStyle(
                                          color: (isProductUnavailable || isStateRestricted)
                                              ? Colors.red 
                                              : ((!isStoreActive || isOutOfStock) ? Colors.grey : AppColors.primaryGreen),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      if (!isOutOfStock && !isProductUnavailable && !isStateRestricted && hasMultipleVariants) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.add, color: AppColors.primaryGreen, size: 14),
                                      ]
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // End of Stack
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
