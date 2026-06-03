import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/home_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/collection_provider.dart';
import 'dynamic_section_renderer.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/search_bar_widget.dart';
import '../../presentation/widgets/product/freshga_product_card.dart';

class HomeFeedView extends StatefulWidget {
  const HomeFeedView({super.key});

  @override
  State<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends State<HomeFeedView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch all required data dynamically on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadSections();
      context.read<ProductProvider>().loadDiscoveryFeed();
      context.read<BannerProvider>().loadBanners();
      context.read<CategoryProvider>().loadCategories();
      context.read<StoreProvider>().loadFeaturedStores();
      context.read<CollectionProvider>().loadCollections();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final homeProvider = context.read<HomeProvider>();
      if (homeProvider.hasMore && !homeProvider.isPaginating) {
        homeProvider.loadMoreSections();
      } else if (!homeProvider.hasMore) {
        // Only load discovery products once sections are fully loaded
        context.read<ProductProvider>().loadMoreDiscoveryFeed();
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<HomeProvider>().loadSections(refresh: true),
      context.read<ProductProvider>().loadDiscoveryFeed(refresh: true),
      context.read<BannerProvider>().loadBanners(),
      context.read<CategoryProvider>().loadCategories(),
      context.read<StoreProvider>().loadFeaturedStores(),
      context.read<CollectionProvider>().loadCollections(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primaryGreen,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildStickyHeader(context),
                
                // ENGINE 1: DYNAMIC SECTIONS
                Consumer<HomeProvider>(
                  builder: (context, homeProvider, child) {
                    if (homeProvider.isLoading) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                      );
                    }

                    if (homeProvider.error != null) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.terracotta),
                              const SizedBox(height: 16),
                              Text("Failed to load home sections", style: Theme.of(context).textTheme.titleMedium),
                              TextButton(
                                onPressed: _onRefresh,
                                child: const Text("Retry", style: TextStyle(color: AppColors.primaryGreen)),
                              )
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == homeProvider.sections.length) {
                            if (homeProvider.isPaginating) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final section = homeProvider.sections[index];
                          
                          // Dynamically reduce padding around the Trust Strip to keep it tight
                          bool nextIsTrust = index < homeProvider.sections.length - 1 && homeProvider.sections[index + 1].type == 'trustStrip';
                          double bottomGap = 24.0; // Default gap between major sections
                          if (section.type == 'trustStrip' || nextIsTrust) {
                            bottomGap = 8.0;
                          }

                          return Padding(
                            padding: EdgeInsets.only(
                              top: index == 0 ? 16.0 : 0.0, // Add top padding below search bar
                              bottom: bottomGap,
                            ),
                            child: DynamicSectionRenderer(section: section),
                          );
                        },
                        childCount: homeProvider.sections.length + (homeProvider.isPaginating ? 1 : 0),
                      ),
                    );
                  },
                ),

                // ENGINE 2: ENDLESS PRODUCT DISCOVERY GRID
                Consumer2<HomeProvider, ProductProvider>(
                  builder: (context, homeProvider, productProvider, child) {
                    // Only show discovery grid when sections are exhausted
                    if (homeProvider.hasMore) return const SliverToBoxAdapter(child: SizedBox());
                    
                    if (productProvider.discoveryProducts.isEmpty && !productProvider.isLoadingDiscovery) {
                      return const SliverToBoxAdapter(child: SizedBox());
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 16.0, top: 8.0),
                              child: Text(
                                "Discover More For You",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.48, // Matches category_products_screen for FreshgaProductCard
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return FreshgaProductCard(
                                  product: productProvider.discoveryProducts[index],
                                );
                              },
                              childCount: productProvider.discoveryProducts.length,
                            ),
                          ),
                          if (productProvider.isPaginatingDiscovery)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32.0),
                                child: Center(
                                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                                ),
                              ),
                            ),
                          if (!productProvider.hasMoreDiscovery && productProvider.discoveryProducts.isNotEmpty)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Center(
                                  child: Text("You've reached the very end! 🎉", style: TextStyle(color: AppColors.textSecondary)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                // Extra padding at the bottom for floating cart
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return SliverAppBar(
      pinned: false,
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 4,
      shadowColor: AppColors.textSecondary.withOpacity(0.2),
      titleSpacing: 16,
      toolbarHeight: 110,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeader(),
          SizedBox(height: 12),
          SearchBarWidget(),
        ],
      ),
    );
  }
}
