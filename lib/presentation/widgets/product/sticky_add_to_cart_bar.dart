import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/cart_provider.dart';

import '../../../providers/customer_provider.dart';

class StickyAddToCartBar extends StatelessWidget {
  const StickyAddToCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Consumer2<ProductProvider, CustomerProvider>(
        builder: (context, provider, customerProvider, child) {
          final product = provider.currentProduct;
          final customerState = customerProvider.currentCustomer?.state;
          
          final bool isStateRestricted = product != null &&
              !product.canSellPanIndia && 
              product.state.isNotEmpty && 
              customerState != null && 
              customerState.isNotEmpty && 
              product.state.toLowerCase() != customerState.toLowerCase();

          final isAdding = provider.isAddingToCart;
          return Row(
            children: [
              // Quantity Selector
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      color: provider.quantity > 1 ? AppColors.textPrimary : Colors.grey,
                      onPressed: provider.decrementQuantity,
                    ),
                    Text(
                      '${provider.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      color: provider.quantity < 10 ? AppColors.textPrimary : Colors.grey,
                      onPressed: provider.incrementQuantity,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Add to Cart Button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isAdding || !provider.isStoreActive || provider.currentProduct?.status == 'Unavailable' || isStateRestricted ? null : () {
                      final product = provider.currentProduct;
                      if (product == null || provider.variants.isEmpty) return;
                      
                      final variant = provider.variants[provider.selectedVariantIndex];
                      
                      // Check stock
                      if (!variant.inStock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("This variant is currently out of stock."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Provider.of<CartProvider>(context, listen: false).addToCart(
                        product: product,
                        variant: variant,
                        quantity: provider.quantity,
                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Added ${provider.quantity} to cart!"),
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppColors.primaryGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isStateRestricted 
                          ? Colors.grey.shade400 
                          : (provider.currentProduct?.status == 'Unavailable' 
                              ? Colors.red.shade400 
                              : (!provider.isStoreActive ? Colors.grey.shade400 : AppColors.primaryGreen)),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isAdding
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart_outlined, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isStateRestricted
                                    ? "Not Deliverable"
                                    : (!provider.isStoreActive 
                                        ? "Store Paused" 
                                        : (provider.currentProduct?.status == 'Unavailable' ? "Unavailable" : "Add to Cart")),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                "₹${(provider.currentVariantPrice * provider.quantity).toInt()}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
