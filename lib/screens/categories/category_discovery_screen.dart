import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/subcategory_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/category_service.dart';
import '../search/search_screen.dart';
import 'category_products_screen.dart';

class CategoryDiscoveryScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryDiscoveryScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryDiscoveryScreen> createState() => _CategoryDiscoveryScreenState();
}

class _CategoryDiscoveryScreenState extends State<CategoryDiscoveryScreen> {
  final CategoryService _categoryService = CategoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: CustomScrollView(
        slivers: [
          _buildHeroBanner(),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Browse Sub Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          _buildSubCategoriesList(),
          _buildBottomRequestCard(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // padding for scrolling
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.category.name,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFF9F5EC), // Warm background color from image
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Image on the right
              if (widget.category.imageUrl.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.category.imageUrl,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              // Text Content
              Positioned(
                left: 20,
                top: 24,
                bottom: 20,
                right: 180, // Prevent overlap with image
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.category.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E3A2F), // Dark green text from image
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.category.description.isNotEmpty) ...[
                      Text(
                        widget.category.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A5D54),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F0DE), // Light green pill
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.category.itemCount}+ Items',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E5B42), // Dark green text for pill
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoriesList() {
    return StreamBuilder<List<SubCategoryModel>>(
      stream: _categoryService.streamSubCategories(widget.category.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text(
                'Error loading subcategories.',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final subCategories = snapshot.data ?? [];

        if (subCategories.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  "No subcategories available yet",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final subCategory = subCategories[index];
                return _SubCategoryCard(
                  subCategory: subCategory,
                  category: widget.category,
                  categoryService: _categoryService,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryProductsScreen(
                          categoryId: widget.category.id,
                          categoryName: widget.category.name,
                          selectedSubCategoryId: subCategory.id,
                          selectedSubCategoryName: subCategory.name,
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: subCategories.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomRequestCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F3), // Light greenish-grey background
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 1.5),
                  color: Colors.transparent,
                ),
                child: const Center(
                  child: Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Can't find what you're looking for?",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Request a product from your favourite stores.",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text("Request Now"),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubCategoryCard extends StatelessWidget {
  final SubCategoryModel subCategory;
  final CategoryModel category;
  final CategoryService categoryService;
  final VoidCallback onTap;

  const _SubCategoryCard({
    required this.subCategory,
    required this.category,
    required this.categoryService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: subCategory.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: subCategory.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade100),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.category, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subCategory.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StreamBuilder<int>(
                    stream: categoryService.streamSubCategoryProductCount(category.id, subCategory.id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count+ Items',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
