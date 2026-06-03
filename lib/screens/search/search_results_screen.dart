import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/search_provider.dart';
import '../../providers/customer_provider.dart';
import '../../presentation/widgets/product/freshga_product_card.dart';
import '../../widgets/search/store_search_card.dart';
import '../../widgets/search/search_loading_shimmer.dart';

import '../categories/widgets/filter_sort_bar.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentSort = 'Relevance';
  int _appliedFilters = 0;
  bool _isNearMeActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Rebuild on tab switch
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Set<String> _selectedFilters = {};

  void _showSortSheet() {
    final isStoresTab = _tabController.index == 1;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text("Sort By", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              const Divider(),
              _buildSortOption("Relevance"),
              if (!isStoresTab) ...[
                _buildSortOption("Price: Low to High"),
                _buildSortOption("Price: High to Low"),
              ],
              _buildSortOption("Rating: High to Low"),
              if (isStoresTab) ...[
                _buildSortOption("Most Popular"),
                _buildSortOption("Newest Sellers"),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String sortName) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      title: Text(sortName, style: TextStyle(fontWeight: _currentSort == sortName ? FontWeight.bold : FontWeight.normal)),
      trailing: _currentSort == sortName ? const Icon(Icons.check_circle, color: AppColors.primaryGreen) : null,
      onTap: () {
        setState(() {
          _currentSort = sortName;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showFilterSheet() {
    final provider = Provider.of<SearchProvider>(context, listen: false);
    final isStoresTab = _tabController.index == 1;
    
    // Extract unique dynamic tags based on the active tab
    final Set<String> availableTags = {};
    if (isStoresTab) {
      // For stores, extract unique categories
      for (var s in provider.searchResultsStores) {
        availableTags.addAll(s.categories);
      }
    } else {
      // For products, extract unique tags
      for (var p in provider.searchResultsProducts) {
        availableTags.addAll(p.tags);
      }
    }
    
    // Sort tags alphabetically
    final List<String> sortedTags = availableTags.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      Text(isStoresTab ? "Categories" : "Tags & Dietary", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (sortedTags.isEmpty)
                        Text(isStoresTab ? "No categories available." : "No specific tags available.", style: const TextStyle(color: Colors.grey)),
                      ...sortedTags.map((tag) => _buildFilterCheckbox(tag)),
                      const SizedBox(height: 24),
                      const Text("Seller Rating", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      _buildFilterCheckbox("4.0+ Stars"),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Apply Filters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterCheckbox(String label) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          activeColor: AppColors.primaryGreen,
          value: _selectedFilters.contains(label),
          onChanged: (bool? value) {
            setModalState(() {
              if (value == true) {
                _selectedFilters.add(label);
              } else {
                _selectedFilters.remove(label);
              }
            });
            setState(() {
              _appliedFilters = _selectedFilters.length;
            });
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStoresTab = _tabController.index == 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const SearchLoadingShimmer();
          }

          return Column(
            children: [
              _buildTabSwitcher(),
              FilterSortBar(
                appliedFiltersCount: _appliedFilters,
                currentSort: _currentSort,
                onFilterTap: _showFilterSheet,
                onSortTap: _showSortSheet,
                isNearMeActive: _isNearMeActive,
                onNearMeTap: () {
                  setState(() {
                    _isNearMeActive = !_isNearMeActive;
                  });
                },
                isRatingActive: _selectedFilters.contains("4.0+ Stars"),
                onRatingTap: () {
                  setState(() {
                    if (_selectedFilters.contains("4.0+ Stars")) {
                      _selectedFilters.remove("4.0+ Stars");
                    } else {
                      _selectedFilters.add("4.0+ Stars");
                    }
                    _appliedFilters = _selectedFilters.length;
                  });
                },
                isProductsTab: !isStoresTab,
                isDiscountActive: _selectedFilters.contains("On Sale"),
                onDiscountTap: () {
                  setState(() {
                    if (_selectedFilters.contains("On Sale")) {
                      _selectedFilters.remove("On Sale");
                    } else {
                      _selectedFilters.add("On Sale");
                    }
                    _appliedFilters = _selectedFilters.length;
                  });
                },
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    );
                  },
                  child: CustomScrollView(
                    key: ValueKey('$_currentSort-$_appliedFilters-$_isNearMeActive-${_tabController.index}'),
                    slivers: [
                      if (!isStoresTab)
                        _buildProductsGrid(provider)
                      else
                        _buildStoresList(provider),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ),
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
      title: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          return Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.searchQuery,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () {
                    provider.clearSearch();
                    Navigator.pop(context); // Go back to search screen
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.cancel, color: Colors.grey, size: 16),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
          onPressed: () {}, // Navigate to cart
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.primaryGreen,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelPadding: EdgeInsets.zero,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: "Products"),
            Tab(text: "Stores"),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(SearchProvider provider) {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    List<ProductModel> products = List.from(provider.searchResultsProducts);
    
    // Apply Near Me filter
    if (_isNearMeActive) {
      final String userCity = customerProvider.currentCustomer?.selectedLocation?['city'] ?? '';
      if (userCity.isNotEmpty) {
        // Find stores in the user's city
        final nearMeStoreIds = provider.searchResultsStores
            .where((s) => s.city.toLowerCase() == userCity.toLowerCase())
            .map((s) => s.id)
            .toSet();
            
        // Filter products to only those sold by nearby stores
        products = products.where((p) => nearMeStoreIds.contains(p.storeId)).toList();
      }
    }

    // Apply dynamic filters
    if (_selectedFilters.isNotEmpty) {
      final selectedTags = _selectedFilters.where((f) => f != "4.0+ Stars" && f != "On Sale").toList();
      
      if (selectedTags.isNotEmpty) {
        // Filter products that contain ANY of the selected tags
        products = products.where((p) => selectedTags.any((tag) => p.tags.contains(tag))).toList();
      }

      if (_selectedFilters.contains("4.0+ Stars")) {
        products = products.where((p) => p.rating >= 4.0).toList();
      }
      
      if (_selectedFilters.contains("On Sale")) {
        // A product is on sale if it has an original price strictly greater than the current selling price
        products = products.where((p) => p.originalPrice > p.price).toList();
      }
    }

    // Apply sorting
    if (_currentSort == 'Price: Low to High') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_currentSort == 'Price: High to Low') {
      products.sort((a, b) => b.price.compareTo(a.price));
    } else if (_currentSort == 'Rating: High to Low') {
      products.sort((a, b) => b.rating.compareTo(a.rating));
    }

    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text("No products found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text("Try adjusting your filters or search terms", style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.48,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
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

  Widget _buildStoresTab(SearchProvider provider) {
    // Removed because we are using _buildStoresList now
    return const SizedBox();
  }

  Widget _buildStoresList(SearchProvider provider) {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    List<StoreModel> stores = List.from(provider.searchResultsStores);
    
    // Apply Near Me filter
    if (_isNearMeActive) {
      final String userCity = customerProvider.currentCustomer?.selectedLocation?['city'] ?? '';
      if (userCity.isNotEmpty) {
        stores = stores.where((s) => s.city.toLowerCase() == userCity.toLowerCase()).toList();
      }
    }

    // Apply dynamic filters
    if (_selectedFilters.isNotEmpty) {
      final selectedTags = _selectedFilters.where((f) => f != "4.0+ Stars" && f != "On Sale").toList();
      
      if (selectedTags.isNotEmpty) {
        // Filter stores that contain ANY of the selected tags in their categories
        stores = stores.where((s) => selectedTags.any((tag) => s.categories.contains(tag))).toList();
      }

      if (_selectedFilters.contains("4.0+ Stars")) {
        stores = stores.where((s) => s.rating >= 4.0).toList();
      }
    }

    // Apply sorting
    if (_currentSort == 'Rating: High to Low') {
      stores.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_currentSort == 'Most Popular') {
      stores.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
    } else if (_currentSort == 'Newest Sellers') {
      // Fallback sorting by ID if createdAt is unavailable, larger IDs loosely mean newer documents
      stores.sort((a, b) => b.id.compareTo(a.id));
    }
    
    if (stores.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text("No stores found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text("We couldn't find any homemade sellers for this query.", style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: StoreSearchCard(store: stores[index]),
            );
          },
          childCount: stores.length,
        ),
      ),
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
