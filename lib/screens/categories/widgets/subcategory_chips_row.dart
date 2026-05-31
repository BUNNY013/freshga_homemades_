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
        if (!snapshot.hasData) return const SizedBox(height: 110);
        
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
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () => onSelected(id),
        child: SizedBox(
          width: 80, // Fixed width guarantees perfect equal gaps
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Center(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl, 
                          width: 70, 
                          height: 70, 
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => const Icon(Icons.category, color: Colors.grey),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                             color: Colors.white,
                             shape: BoxShape.circle,
                             border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: Icon(id == null ? Icons.grid_view_rounded : Icons.category, 
                              color: AppColors.textSecondary),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, // Small and premium
                  height: 1.2, // Tight line height
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primaryGreen : Colors.grey.shade700,
                ),
                maxLines: 2, // Allow wrapping to 2 lines like Swiggy
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
