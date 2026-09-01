import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../screens/product/product_images_fullscreen_screen.dart';

class ProductImageSection extends StatefulWidget {
  final ProductModel product;

  const ProductImageSection({super.key, required this.product});

  @override
  State<ProductImageSection> createState() => _ProductImageSectionState();
}

class _ProductImageSectionState extends State<ProductImageSection> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> displayImages = widget.product.images.isNotEmpty
        ? widget.product.images
        : [widget.product.imageUrl];

    return Stack(
      children: [
        // Immersive Image Slideshow
        AspectRatio(
          aspectRatio: 4 / 3, // Premium 4:3 ratio matching product cards
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: displayImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductImagesFullscreenScreen(
                        product: widget.product,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: index == 0
                      ? 'product_image_${widget.product.id}'
                      : 'product_image_${widget.product.id}_$index',
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.zero,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: displayImages[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey.shade50),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade50,
                        child: const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
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
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
              ),
            ),
          ),
        ),

        // Dots Indicator
        if (displayImages.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(displayImages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 8 : 6,
                  height: _currentIndex == index ? 8 : 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.primaryGreen
                        : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
