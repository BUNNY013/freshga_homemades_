import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';
import '../../widgets/store/store_header.dart';
import '../../widgets/store/store_info_section.dart';
import '../../widgets/store/social_links_row.dart';
import '../../widgets/store/store_tab_bar.dart';
import '../../widgets/store/about_store_section.dart';
import '../../widgets/store/store_loading_shimmer.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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

          final store = provider.currentStore;
          if (store == null) {
            return _buildErrorState("Store not found");
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                StoreHeader(bannerUrl: store.bannerUrl),
                SliverToBoxAdapter(
                  child: StoreInfoSection(store: store),
                ),
                if (store.instagramLink.isNotEmpty || store.youtubeLink.isNotEmpty || store.facebookLink.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SocialLinksRow(store: store),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StoreTabBarDelegate(
                    tabBar: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryGreen,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primaryGreen,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: "Shop"),
                        Tab(text: "Products"),
                        Tab(text: "About"),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildShopTab(provider),
                _buildProductsTab(provider),
                AboutStoreSection(store: store),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }

  Widget _buildShopTab(StoreProvider provider) {
    final featured = provider.featuredProducts;
    
    if (featured.isEmpty) {
      return const Center(child: Text("Welcome to our shop!", style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text("Featured Goodness", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 160,
                  child: ProductCard(product: featured[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text("All Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 12,
            children: provider.currentStore!.categories.map((cat) => Chip(
              label: Text(cat, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFFF0FDF4),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            )).toList(),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProductsTab(StoreProvider provider) {
    if (provider.isLoadingProducts && provider.storeProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    if (provider.storeProducts.isEmpty) {
      return const Center(child: Text("No products available", style: TextStyle(color: AppColors.textSecondary)));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          if (provider.hasMoreProducts && !provider.isLoadingProducts) {
            provider.loadStoreProducts(widget.storeId);
          }
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: provider.storeProducts.length + (provider.hasMoreProducts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.storeProducts.length) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          return ProductCard(product: provider.storeProducts[index]);
        },
      ),
    );
  }
}
