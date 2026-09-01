import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/category_provider.dart';

class DynamicCategoryChips extends StatefulWidget {
  const DynamicCategoryChips({super.key});

  @override
  State<DynamicCategoryChips> createState() => _DynamicCategoryChipsState();
}

class _DynamicCategoryChipsState extends State<DynamicCategoryChips> {
  final ScrollController _scrollController = ScrollController();
  String _lastSelected = "All";

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, _) {
        final categories = provider.availableCategories;
        if (categories.isEmpty) return const SizedBox.shrink();

        final items = [
          {'id': 'All', 'name': 'All'},
          ...categories.entries.map((e) => {'id': e.key, 'name': e.value}),
        ];

        if (_lastSelected != provider.selectedCategory) {
          _lastSelected = provider.selectedCategory;
          final index = items.indexWhere((c) => c['id'] == _lastSelected);
          if (index != -1 && _scrollController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                double offset =
                    (index * 92.0) -
                    (MediaQuery.of(context).size.width / 2) +
                    46.0;
                if (offset < 0) offset = 0;
                if (offset > _scrollController.position.maxScrollExtent) {
                  offset = _scrollController.position.maxScrollExtent;
                }
                _scrollController.animateTo(
                  offset,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }
        }

        return SizedBox(
          height: 112, // Increased for bigger, premium circles
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final cat = items[index];
              final isSelected = provider.selectedCategory == cat['id'];

              String? imageUrl;
              if (cat['id'] != 'All') {
                final catProvider = Provider.of<CategoryProvider>(
                  context,
                  listen: false,
                );
                try {
                  final categoryModel = catProvider.categories.firstWhere(
                    (c) => c.id == cat['id'],
                  );
                  imageUrl = categoryModel.imageUrl;
                } catch (e) {
                  // Image not found
                }
              }

              return GestureDetector(
                onTap: () => provider.setCategory(cat['id']!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: SizedBox(
                    width: 80, // Wider for bigger circles
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFFF0FDF4)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : Colors.grey.shade200,
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
                          child: ClipOval(
                            child: cat['id'] == 'All'
                                ? Icon(
                                    Icons.grid_view,
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : Colors.grey,
                                    size: 32,
                                  )
                                : (imageUrl != null && imageUrl.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Container(color: Colors.grey.shade100),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.fastfood_outlined,
                                      color: isSelected
                                          ? AppColors.primaryGreen
                                          : Colors.grey,
                                      size: 32,
                                    ),
                                  )
                                : Icon(
                                    Icons.fastfood_outlined,
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : Colors.grey,
                                    size: 32,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['name']!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.2, // Tighter line height for 2 lines
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
