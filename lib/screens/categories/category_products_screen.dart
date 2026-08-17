import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../services/store_service.dart';
import '../search/search_screen.dart';
import '../../presentation/widgets/product/freshga_product_card.dart';
import 'widgets/category_hero_card.dart';
import 'widgets/discovery_store_card.dart';
import 'widgets/filter_sort_bar.dart';
import 'widgets/subcategory_chips_row.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String? selectedSubCategoryId;
  final String? selectedSubCategoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.selectedSubCategoryId,
    this.selectedSubCategoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSubCategoryId;
  String _currentSort = 'Popularity';
  int _appliedFilters = 0;
  CategoryModel? _category;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Rebuild for hero banner switch
      }
    });
    _selectedSubCategoryId = widget.selectedSubCategoryId;
    _fetchCategory();
  }
  
  Future<void> _fetchCategory() async {
    final categories = await CategoryService().getActiveCategories();
    try {
      final cat = categories.firstWhere((c) => c.categoryId == widget.categoryId || c.id == widget.categoryId);
      setState(() {
        _category = cat;
      });
    } catch (e) {
      // Category not found fallback
      setState(() {
        _category = CategoryModel(
          categoryId: widget.categoryId,
          name: widget.categoryName,
          slug: '',
          image: const {'url': '', 'storagePath': ''},
          itemCount: 0,
          status: 'active',
          displayIndex: 0,
          description: '',
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStoresTab = _tabController.index == 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _category == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : StreamBuilder<List<ProductModel>>(
              stream: ProductService().streamProductsByCategory(widget.categoryId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }
                
                final allProducts = snapshot.data!;
                List<ProductModel> filteredProducts = allProducts;
                
                if (_selectedSubCategoryId != null) {
                  filteredProducts = filteredProducts.where((p) => p.subCategoryIds.contains(_selectedSubCategoryId)).toList();
                }
                
                // Mock Sort
                if (_currentSort == 'Price: Low to High') {
                  filteredProducts.sort((a, b) => a.price.compareTo(b.price));
                } else if (_currentSort == 'Price: High to Low') {
                  filteredProducts.sort((a, b) => b.price.compareTo(a.price));
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildTabSwitcher(),
                          CategoryHeroCard(category: _category!, isStoresTab: isStoresTab),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyHeaderDelegate(
                        height: 190.0, // Subcategory chips (~130px) + Compact Filter Bar (~60px)
                        child: Column(
                          children: [
                            SubcategoryChipsRow(
                              categoryId: widget.categoryId,
                              selectedSubCategoryId: _selectedSubCategoryId,
                              onSelected: (id) {
                                setState(() {
                                  _selectedSubCategoryId = id;
                                });
                              },
                            ),
                            FilterSortBar(
                              appliedFiltersCount: _appliedFilters,
                              currentSort: _currentSort,
                              onFilterTap: _showFilterSheet,
                              onSortTap: _showSortSheet,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isStoresTab)
                      _buildProductsGrid(filteredProducts)
                    else
                      _buildStoresList(filteredProducts),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.categoryName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            _tabController.index == 0 ? "Products" : "Stores",
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
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
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
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

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.primaryGreen,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: "Products"),
            Tab(text: "Stores"),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                "No products found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                "Try selecting a different subcategory or filter.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.45,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return FreshgaProductCard(product: products[index]);
          },
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildStoresList(List<ProductModel> products) {
    final storeIds = products.map((p) => p.storeId).where((id) => id.isNotEmpty).toSet().toList();
    
    if (storeIds.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                "No stores found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                "Try selecting a different subcategory.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: _StoresFetcher(storeIds: storeIds),
    );
  }

  void _showFilterSheet() {
    // Basic placeholder for bottom sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ["Veg Only", "Non-Veg", "Spicy", "Sweet", "Homemade Only"].map((e) => 
                  ChoiceChip(
                    label: Text(e),
                    selected: false,
                    onSelected: (val) {},
                  )
                ).toList(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _appliedFilters = 1);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Sort By", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...['Popularity', 'Newest', 'Price: Low to High', 'Price: High to Low', 'Highest Rated'].map((sort) => 
                ListTile(
                  title: Text(sort, style: TextStyle(fontWeight: _currentSort == sort ? FontWeight.bold : FontWeight.normal)),
                  trailing: _currentSort == sort ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
                  onTap: () {
                    setState(() => _currentSort = sort);
                    Navigator.pop(context);
                  },
                )
              ),
            ],
          ),
        );
      }
    );
  }
}

class _StoresFetcher extends StatefulWidget {
  final List<String> storeIds;

  const _StoresFetcher({required this.storeIds});

  @override
  State<_StoresFetcher> createState() => _StoresFetcherState();
}

class _StoresFetcherState extends State<_StoresFetcher> {
  late Future<List<StoreModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = StoreService().getStoresByIds(widget.storeIds);
  }

  @override
  void didUpdateWidget(covariant _StoresFetcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-fetch if store IDs actually changed
    if (widget.storeIds.join(',') != oldWidget.storeIds.join(',')) {
      _future = StoreService().getStoresByIds(widget.storeIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StoreModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return DiscoveryStoreCard(store: snapshot.data![index]);
          },
        );
      },
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
