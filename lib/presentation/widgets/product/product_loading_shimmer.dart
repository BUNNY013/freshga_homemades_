import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProductLoadingShimmer extends StatelessWidget {
  const ProductLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Shimmer
            _buildShimmerBlock(height: 400, width: double.infinity, borderRadius: 0),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildShimmerBlock(height: 28, width: 200),
                  const SizedBox(height: 8),
                  // Store
                  _buildShimmerBlock(height: 16, width: 120),
                  const SizedBox(height: 16),
                  // Price
                  _buildShimmerBlock(height: 24, width: 80),
                  const SizedBox(height: 24),
                  
                  // Variants
                  _buildShimmerBlock(height: 16, width: 100),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildShimmerBlock(height: 60)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildShimmerBlock(height: 60)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildShimmerBlock(height: 60)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Benefits
                  _buildShimmerBlock(height: 16, width: 150),
                  const SizedBox(height: 12),
                  _buildShimmerBlock(height: 16, width: double.infinity),
                  const SizedBox(height: 8),
                  _buildShimmerBlock(height: 16, width: double.infinity),
                  const SizedBox(height: 8),
                  _buildShimmerBlock(height: 16, width: 200),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBlock({required double height, double? width, double borderRadius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
