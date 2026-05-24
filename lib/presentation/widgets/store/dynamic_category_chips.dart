import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';

class DynamicCategoryChips extends StatelessWidget {
  const DynamicCategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, _) {
        final categories = provider.availableCategories;
        if (categories.isEmpty) return const SizedBox.shrink();

        final items = [
          {'id': 'All', 'name': 'All'},
          ...categories.entries.map((e) => {'id': e.key, 'name': e.value})
        ];

        return SizedBox(
          height: 100, // Room for circle + text
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final cat = items[index];
              final isSelected = provider.selectedCategory == cat['id'];

              return GestureDetector(
                onTap: () => provider.setCategory(cat['id']!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: cat['id'] == 'All' 
                            ? Icon(Icons.grid_view, color: isSelected ? AppColors.primaryGreen : Colors.grey)
                            : Icon(Icons.fastfood_outlined, color: isSelected ? AppColors.primaryGreen : Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
