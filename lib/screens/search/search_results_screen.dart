import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/search_provider.dart';
import '../../presentation/widgets/product/freshga_product_card.dart';
import '../../widgets/search/store_search_card.dart';
import '../../widgets/search/search_loading_shimmer.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Consumer<SearchProvider>(
          builder: (context, provider, child) {
            return Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
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
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
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
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {}, // Navigate to cart
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const SearchLoadingShimmer();
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: AppColors.primaryGreen,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primaryGreen,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: "Products"),
                    Tab(text: "Stores"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildProductsTab(provider),
                      _buildStoresTab(provider),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsTab(SearchProvider provider) {
    if (provider.searchResultsProducts.isEmpty) {
      return const Center(
        child: Text("No products found", style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.48,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: provider.searchResultsProducts.length,
        itemBuilder: (context, index) {
          return FreshgaProductCard(product: provider.searchResultsProducts[index]);
        },
      ),
    );
  }

  Widget _buildStoresTab(SearchProvider provider) {
    if (provider.searchResultsStores.isEmpty) {
      return const Center(
        child: Text("No stores found", style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: provider.searchResultsStores.length,
      itemBuilder: (context, index) {
        return StoreSearchCard(store: provider.searchResultsStores[index]);
      },
    );
  }
}
