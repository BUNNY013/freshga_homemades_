import 'package:flutter/material.dart';
import '../../../models/product_model.dart';

class ProductInfoCards extends StatelessWidget {
  final ProductModel product;

  const ProductInfoCards({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            icon: Icons.calendar_today_outlined,
            title: "Shelf Life",
            value: product.shelfLife.isNotEmpty ? product.shelfLife : "N/A",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            icon: Icons.eco_outlined,
            title: "Dispatch Time",
            value: product.dispatchTime.isNotEmpty ? product.dispatchTime : "N/A",
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF4B8B4D), size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
