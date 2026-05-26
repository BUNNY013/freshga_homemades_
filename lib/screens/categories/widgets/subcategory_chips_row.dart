import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/subcategory_model.dart';
import '../../../services/category_service.dart';

class SubcategoryChipsRow extends StatelessWidget {
  final String categoryId;
  final String? selectedSubCategoryId;
  final Function(String?) onSelected;

  const SubcategoryChipsRow({
    super.key,
    required this.categoryId,
    this.selectedSubCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SubCategoryModel>>(
      stream: CategoryService().streamSubCategories(categoryId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);
        
        final subCategories = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChip('All', null, selectedSubCategoryId == null, null),
              ...subCategories.map((sub) => _buildChip(
                sub.name,
                sub.id,
                selectedSubCategoryId == sub.id,
                sub.imageUrl,
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, String? id, bool isSelected, String? imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () => onSelected(id),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey.shade200,
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Center(
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl, 
                          width: 48, 
                          height: 48, 
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(Icons.category, color: Colors.grey),
                        ),
                      )
                    : Icon(id == null ? Icons.grid_view_rounded : Icons.category, 
                        color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
