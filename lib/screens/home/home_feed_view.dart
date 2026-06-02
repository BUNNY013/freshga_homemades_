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

class HomeFeedView extends StatefulWidget {
  const HomeFeedView({super.key});

  @override
  State<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends State<HomeFeedView> {
  @override
  void initState() {
    super.initState();
    // Fetch all required data dynamically on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadSections();
      context.read<BannerProvider>().loadBanners();
      context.read<CategoryProvider>().loadCategories();
      context.read<StoreProvider>().loadFeaturedStores();
      context.read<ProductProvider>().loadTrendingProducts();
      context.read<CollectionProvider>().loadCollections();
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<HomeProvider>().loadSections(),
      context.read<BannerProvider>().loadBanners(),
      context.read<CategoryProvider>().loadCategories(),
      context.read<StoreProvider>().loadFeaturedStores(),
      context.read<ProductProvider>().loadTrendingProducts(),
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
              slivers: [
                _buildStickyHeader(context),
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

                    if (homeProvider.sections.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(child: Text("No content available at the moment.")),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final section = homeProvider.sections[index];
                          
                          // Dynamically reduce padding around the Trust Strip to keep it tight
                          bool nextIsTrust = index < homeProvider.sections.length - 1 && homeProvider.sections[index + 1].type == 'trustStrip';
                          double bottomGap = 24.0; // Default gap between major sections
                          if (section.type == 'trustStrip' || nextIsTrust) {
                            bottomGap = 8.0;
                          }

                          return Padding(
                            padding: EdgeInsets.only(bottom: bottomGap),
                            child: DynamicSectionRenderer(section: section),
                          );
                        },
                        childCount: homeProvider.sections.length,
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
