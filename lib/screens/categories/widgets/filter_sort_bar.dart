import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FilterSortBar extends StatelessWidget {
  final int appliedFiltersCount;
  final String currentSort;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;
  final bool isNearMeActive;
  final VoidCallback? onNearMeTap;
  final bool isRatingActive;
  final VoidCallback? onRatingTap;
  final bool isProductsTab;
  final bool isDiscountActive;
  final VoidCallback? onDiscountTap;

  const FilterSortBar({
    super.key,
    required this.appliedFiltersCount,
    required this.currentSort,
    required this.onFilterTap,
    required this.onSortTap,
    this.isNearMeActive = false,
    this.onNearMeTap,
    this.isRatingActive = false,
    this.onRatingTap,
    this.isProductsTab = true,
    this.isDiscountActive = false,
    this.onDiscountTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildFilterChip(),
          const SizedBox(width: 8),
          _buildSortChip(),
          const SizedBox(width: 8),
          _buildExtraChip(
            Icons.location_on_outlined,
            "Near Me",
            isActive: isNearMeActive,
            onTap: onNearMeTap,
          ),
          const SizedBox(width: 8),
          _buildExtraChip(
            Icons.star_outline_rounded,
            "4.0+",
            color: Colors.orange,
            isActive: isRatingActive,
            onTap: onRatingTap,
          ),
          if (isProductsTab) ...[
            const SizedBox(width: 8),
            _buildExtraChip(
              Icons.local_offer_outlined,
              "On Sale",
              color: AppColors.primaryGreen,
              isActive: isDiscountActive,
              onTap: onDiscountTap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    final hasFilters = appliedFiltersCount > 0;
    return GestureDetector(
      onTap: onFilterTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: hasFilters
              ? AppColors.primaryGreen.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasFilters ? AppColors.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            const Text(
              "Filter",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.tune, size: 16, color: AppColors.textPrimary),
            if (appliedFiltersCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$appliedFiltersCount",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip() {
    return GestureDetector(
      onTap: onSortTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Text(
              "Sort by",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraChip(
    IconData icon,
    String label, {
    Color? color,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryGreen.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? AppColors.primaryGreen
                  : (color ?? AppColors.textPrimary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive
                    ? AppColors.primaryGreen
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
