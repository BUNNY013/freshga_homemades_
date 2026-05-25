import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';

class ProductHighlights extends StatelessWidget {
  final ProductModel product;

  const ProductHighlights({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    if (product.tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: product.tags.take(4).map((tag) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryGreen,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  tag,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
