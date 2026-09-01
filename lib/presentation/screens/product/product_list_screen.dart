import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../widgets/product/freshga_product_card.dart';

class ProductListScreen extends StatelessWidget {
  final String title;
  final List<ProductModel> products;

  const ProductListScreen({
    super.key,
    required this.title,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: products.isEmpty
          ? const Center(
              child: Text(
                "No products found",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 100,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.45,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return FreshgaProductCard(product: products[index]);
              },
            ),
    );
  }
}
