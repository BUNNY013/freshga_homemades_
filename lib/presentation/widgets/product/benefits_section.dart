import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';

class BenefitsSection extends StatelessWidget {
  final ProductModel product;

  const BenefitsSection({super.key, required this.product});

  List<String> _generateBenefits() {
    // Generate benefits dynamically based on tags or categories.
    // In a real app, this might come directly from the backend.
    List<String> benefits = [];
    if (product.tags.contains('Homemade'))
      benefits.add('Handmade In Small Batches');
    if (product.tags.contains('Organic')) benefits.add('Rich In Antioxidants');
    if (product.categoryId.toLowerCase() == 'pickles')
      benefits.add('Traditional Recipe');
    if (product.tags.contains('No Preservatives'))
      benefits.add('100% Natural Ingredients');

    // Add default benefits if list is too small
    if (benefits.isEmpty) {
      benefits.addAll([
        'Freshly Prepared',
        'Authentic Taste',
        'Quality Ingredients',
      ]);
    }

    return benefits.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final benefits = _generateBenefits();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Why you'll love it",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...benefits.map(
          (benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    benefit,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
