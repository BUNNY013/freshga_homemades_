import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../screens/product/product_images_fullscreen_screen.dart';

class ProductImageSection extends StatelessWidget {
  final ProductModel product;

  const ProductImageSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Immersive Image
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductImagesFullscreenScreen(product: product),
              ),
            );
          },
          child: Hero(
            tag: 'product_image_${product.id}',
            child: Container(
              height: 400, // Large immersive size
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        
        // Dark Warm Gradient Overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Floating Action Buttons (Top)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGlassButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
              Row(
                children: [
                  Consumer<ProductProvider>(
                    builder: (context, provider, child) {
                      return _buildGlassButton(
                        icon: provider.isWishlisted ? Icons.favorite : Icons.favorite_border,
                        iconColor: provider.isWishlisted ? Colors.red : Colors.white,
                        onTap: () => provider.toggleWishlist(),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildGlassButton(
                    icon: Icons.share_outlined,
                    onTap: () {
                      // Share action
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildGlassButton(
                    icon: Icons.shopping_cart_outlined,
                    hasBadge: true,
                    onTap: () {
                      // Navigate to cart
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
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
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
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
                  '2', // Dummy cart count
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            )
        ],
      ),
    );
  }
}
