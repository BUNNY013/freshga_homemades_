import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FilterSortBar extends StatelessWidget {
  final int appliedFiltersCount;
  final String currentSort;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;

  const FilterSortBar({
    super.key,
    required this.appliedFiltersCount,
    required this.currentSort,
    required this.onFilterTap,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onFilterTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined, size: 20, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Filter", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        if (appliedFiltersCount > 0)
                          Text("$appliedFiltersCount Applied", style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onSortTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_vert, size: 20, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Sort", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text(currentSort, style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
