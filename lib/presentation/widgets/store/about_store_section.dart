import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store_model.dart';
import 'social_links_row.dart';

class AboutStoreSection extends StatelessWidget {
  final StoreModel store;

  const AboutStoreSection({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Our Story",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            store.description.isNotEmpty 
                ? store.description 
                : "Welcome to our store! We source the finest ingredients from local farmers and create homemade products in small batches to ensure authenticity, freshness and quality in every jar.",
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
          ),
          const SizedBox(height: 24),
          
          // Values Badges
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildValueBadge(Icons.eco_outlined, "100% Natural", "No preservatives"),
                _buildValueBadge(Icons.soup_kitchen_outlined, "Small Batch", "Made with love"),
                _buildValueBadge(Icons.health_and_safety_outlined, "Hygienic", "Clean & safe"),
                _buildValueBadge(Icons.compost_outlined, "Sustainable", "Eco friendly"),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            "Business Information",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),

          // Details Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildDetailRow(Icons.calendar_today_outlined, "Established", "Apr 2022"),
                    _buildDetailRow(Icons.storefront_outlined, "Business Type", "Home-based Food Business"),
                    _buildDetailRow(Icons.access_time_outlined, "Dispatch Time", store.dispatchTime),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildDetailRow(Icons.location_on_outlined, "Pickup Location", "Bangalore, Karnataka"),
                    _buildDetailRow(Icons.category_outlined, "Categories", store.categories.join(', ')),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            "Follow Us",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SocialLinksRow(store: store),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildValueBadge(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
