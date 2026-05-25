import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';

class IngredientsSection extends StatelessWidget {
  final ProductModel product;

  const IngredientsSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    if (product.ingredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ingredients",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...product.ingredients.map((ingredient) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.eco, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ingredient,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
