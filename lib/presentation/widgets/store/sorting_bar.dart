import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';

class SortingBar extends StatelessWidget {
  const SortingBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Consumer<StoreProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip(
                  context,
                  "Best Selling",
                  StoreSortType.bestSelling,
                  provider.sortType,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  context,
                  "Newest",
                  StoreSortType.newest,
                  provider.sortType,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  context,
                  "Price: Low to High",
                  StoreSortType.priceLowHigh,
                  provider.sortType,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  context,
                  "Price: High to Low",
                  StoreSortType.priceHighLow,
                  provider.sortType,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    String label,
    StoreSortType type,
    StoreSortType selectedType,
  ) {
    final isSelected = type == selectedType;
    return GestureDetector(
      onTap: () {
        Provider.of<StoreProvider>(context, listen: false).setSortType(type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8F5E9)
              : Colors.white, // Light green if selected
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen.withOpacity(0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected && type == StoreSortType.bestSelling) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: AppColors.primaryGreen,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
