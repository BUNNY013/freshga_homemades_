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
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Text Content (Takes available space naturally)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 8, 24),
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
                          height: 1.2,
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
              ),
              // Fixed 4:3 landscape ratio space for banner image
              if ((widget.category.banner?['url']?.toString() ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 186, // Perfect 4:3 Landscape ratio (140 * 1.33)
                    height: 140,
                    child: CachedNetworkImage(
                      imageUrl: widget.category.banner!['url'].toString(),
                      fit: BoxFit.contain, // Float naturally without zooming
                    ),
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
                child: (widget.category.image?['url']?.toString() ?? '').isNotEmpty
                    ? ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CachedNetworkImage(
                            imageUrl: widget.category.image!['url'].toString(),
                            fit: BoxFit.contain, 
                          ),
                        ),
                      )
                    : const Center(
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
                      "Request ${widget.category.name.toLowerCase()} from your favourite stores.",
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
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15)), // Faint border like screenshot
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12), // Restored padding for a larger card feel
        child: Row(
          children: [
            SizedBox(
              width: 64, // Increased image size
              height: 64,
              child: subCategory.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: subCategory.imageUrl,
                      fit: BoxFit.contain, // Float naturally
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen)
                        )
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey),
                    )
                  : const Icon(Icons.category, color: Colors.grey, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subCategory.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2, // Gives a tighter, more modern look
                    ),
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<int>(
                    stream: categoryService.streamSubCategoryProductCount(category.id, subCategory.id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count+ Items',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
