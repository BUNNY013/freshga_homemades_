import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';

class VariantSelectionBottomSheet extends StatefulWidget {
  final ProductModel product;

  const VariantSelectionBottomSheet({super.key, required this.product});

  @override
  State<VariantSelectionBottomSheet> createState() => _VariantSelectionBottomSheetState();
}

class _VariantSelectionBottomSheetState extends State<VariantSelectionBottomSheet> {
  late ProductVariantModel _selectedVariant;
  bool _isAdding = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Default to the first in-stock variant, or the first variant if all are out of stock
    _selectedVariant = widget.product.variants.firstWhere(
      (v) => v.inStock,
      orElse: () => widget.product.variants.first,
    );
  }

  void _addToCart() async {
    if (!_selectedVariant.inStock) return;
    
    setState(() => _isAdding = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      
      context.read<CartProvider>().addToCart(
        product: widget.product,
        variant: _selectedVariant,
        quantity: _quantity,
      );
      
      Navigator.pop(context); // Close the sheet
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${widget.product.name} (${_selectedVariant.label}) x$_quantity added to cart",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Customize",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Variants List
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shrinkWrap: true,
              itemCount: widget.product.variants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final variant = widget.product.variants[index];
                final bool isSelected = _selectedVariant.id == variant.id;
                final bool hasDiscount = variant.discountPrice > 0 && variant.discountPrice < variant.price;
                final double displayPrice = hasDiscount ? variant.discountPrice : variant.price;
                final int discountPercent = hasDiscount ? (((variant.price - variant.discountPrice) / variant.price) * 100).round() : 0;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryGreen.withOpacity(0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryGreen : Colors.grey.shade200,
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: variant.inStock ? () {
                        setState(() {
                          _selectedVariant = variant;
                          _quantity = 1; // Reset quantity when changing variant
                        });
                      } : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Premium Radio Icon
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            
                            // Label & Discount Tag
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        variant.label,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: variant.inStock ? AppColors.textPrimary : Colors.grey,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      if (hasDiscount) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.red.shade100),
                                          ),
                                          child: Text(
                                            "SAVE $discountPercent%",
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                  if (!variant.inStock) ...[
                                    const SizedBox(height: 4),
                                    const Text("Currently Out of Stock", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500)),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Price
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "₹${displayPrice.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: variant.inStock ? AppColors.primaryGreen : Colors.grey,
                                  ),
                                ),
                                if (hasDiscount)
                                  Text(
                                    "₹${variant.price.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Divider(height: 1),
          
          // Quantity Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Quantity",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        icon: const Icon(Icons.remove, size: 18),
                        color: _quantity > 1 ? AppColors.primaryGreen : Colors.grey,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                      Container(
                        width: 32,
                        alignment: Alignment.center,
                        child: Text(
                          _quantity.toString(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add, size: 18),
                        color: AppColors.primaryGreen,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Add Button
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedVariant.inStock && !_isAdding ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isAdding
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        "Add item • ₹${((_selectedVariant.discountPrice > 0 && _selectedVariant.discountPrice < _selectedVariant.price ? _selectedVariant.discountPrice : _selectedVariant.price) * _quantity).toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
