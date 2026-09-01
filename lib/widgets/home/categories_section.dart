import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import 'section_title.dart';

class CategoriesSection extends StatelessWidget {
  final List<CategoryModel> categories;
  final String title;
  final VoidCallback? onViewAll;
  final Function(CategoryModel)? onCategoryTap;

  const CategoriesSection({
    super.key,
    required this.categories,
    required this.title,
    this.onViewAll,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title, onSeeAll: onViewAll),
        const SizedBox(height: 12),
        SizedBox(
          height: 135,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () {
                  if (onCategoryTap != null) {
                    onCategoryTap!(cat);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Container(
                          key: ValueKey(
                            cat.imageUrl,
                          ), // Forces rebuild when URL changes
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            image: cat.imageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      cat.imageUrl,
                                      maxWidth: 150,
                                      maxHeight: 150,
                                    ),
                                    fit: BoxFit.cover,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.background,
                                      BlendMode.multiply,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 11,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
