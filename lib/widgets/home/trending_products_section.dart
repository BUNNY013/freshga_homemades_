import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'section_title.dart';
import 'product_card.dart';

class TrendingProductsSection extends StatelessWidget {
  final List<ProductModel> products;
  final String title;

  const TrendingProductsSection({super.key, required this.products, required this.title});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title, onSeeAll: () {}),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ProductCard(product: products[index]),
            ),
          ),
        ),
      ],
    );
  }
}
