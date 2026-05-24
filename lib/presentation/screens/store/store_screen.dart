import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';
import '../../widgets/store/store_header.dart';
import '../../widgets/store/store_info_section.dart';
import '../../widgets/store/store_tab_bar.dart';
import '../../widgets/store/about_store_section.dart';
import '../../widgets/store/store_loading_shimmer.dart';
import '../../widgets/store/store_search_bar.dart';
import '../../widgets/store/dynamic_category_chips.dart';
import '../../widgets/store/dynamic_subcategory_chips.dart';
import '../../widgets/store/sorting_bar.dart';
import '../../../widgets/home/product_card.dart';

class StoreScreen extends StatefulWidget {
  final String storeId;

  const StoreScreen({super.key, required this.storeId});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoreProvider>(context, listen: false).loadStoreData(widget.storeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<StoreProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingStore) {
            return const StoreLoadingShimmer();
          }

          if (provider.storeError != null) {
            return _buildErrorState(provider.storeError!);
          }

          if (provider.currentStore == null) {
            return _buildErrorState("Store not found");
          }

          final store = provider.currentStore!;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                StoreHeader(store: store),
                SliverToBoxAdapter(
                  child: StoreInfoSection(store: store),
                ),
                SliverPersistentHeader(
                  delegate: StoreTabBarDelegate(_tabController),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 1. Shop Tab
                _buildShopTab(provider),
                
                // 2. About Tab
                AboutStoreSection(store: store),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopTab(StoreProvider provider) {
    if (provider.isLoadingProducts) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    final products = provider.filteredProducts;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StoreSearchBar(storeName: provider.currentStore!.name),
              const DynamicCategoryChips(),
              const DynamicSubcategoryChips(),
              const SortingBar(),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                "No products found.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.65, // Adjust to fit product cards nicely
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return ProductCard(product: products[index]);
                },
                childCount: products.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100), // Bottom padding
        )
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Provider.of<StoreProvider>(context, listen: false).loadStoreData(widget.storeId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
