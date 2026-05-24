import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';

class DynamicSubcategoryChips extends StatelessWidget {
  const DynamicSubcategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, _) {
        if (provider.selectedCategory == "All") return const SizedBox.shrink();

        // Get subcategories matching the selected category
        final matchingSubs = provider.availableSubcategories.values
            .where((sub) => sub['categoryId'] == provider.selectedCategory)
            .toList();

        if (matchingSubs.isEmpty) return const SizedBox.shrink();

        final items = [
          {'id': 'All', 'name': 'All'},
          ...matchingSubs.map((s) => {'id': s['id'] as String, 'name': s['name'] as String})
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final sub = items[index];
                final isSelected = provider.selectedSubcategory == sub['id'];

                return GestureDetector(
                  onTap: () => provider.setSubcategory(sub['id']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        sub['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
