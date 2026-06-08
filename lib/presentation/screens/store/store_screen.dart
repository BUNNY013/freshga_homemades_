import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';
import '../../../models/product_model.dart';
import '../../widgets/store/store_header.dart';
import '../../widgets/store/store_info_section.dart';
import '../../widgets/store/store_tab_bar.dart';
import '../../widgets/store/about_store_section.dart';
import '../../widgets/store/store_loading_shimmer.dart';

import '../../widgets/store/dynamic_category_chips.dart';
import '../../widgets/store/store_product_list_item.dart';
import '../../widgets/store/store_menu_fab.dart';
import '../../widgets/cart/floating_cart_bar.dart';

class StoreScreen extends StatefulWidget {
  final String storeId;

  const StoreScreen({super.key, required this.storeId});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _collapsedSections = {};
  Map<String, List<ProductModel>> _groupedProducts = {};
  List<String> _sortedKeys = [];

  void _scrollToSection(String categoryId, String sectionName) async {
    final innerController = PrimaryScrollController.of(context);
    final provider = context.read<StoreProvider>();
    
    if (sectionName == "All") {
      provider.setCategory("All");
      innerController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    // First, filter the store to the parent category
    if (provider.selectedCategory != categoryId) {
      provider.setCategory(categoryId);
      // Wait for the UI to rebuild with the filtered products
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    double targetOffset = 0.0;
    for (var section in _sortedKeys) {
      if (section == sectionName) break;
      
      targetOffset += 56.0; // Fixed header height
      if (!_collapsedSections.contains(section)) {
        targetOffset += _groupedProducts[section]!.length * 224.0; // Fixed item height
      }
    }

    // Scroll to the exact pixel offset calculated mathematically
    innerController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
      body: Stack(
        children: [
          Consumer<StoreProvider>(
            builder: (context, provider, child) {
              if (provider.isLoadingStore) {
                return Stack(
                  children: [
                    const StoreLoadingShimmer(),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
                        ),
                      ),
                    ),
                  ],
                );
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
                      pinned: false, // Let the TabBar scroll away as requested
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // 1. Shop Tab
                    Builder(
                      builder: (innerContext) => _buildShopTab(innerContext, provider),
                    ),
                    
                    // 2. About Tab
                    Builder(
                      builder: (innerContext) => CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: AboutStoreSection(store: store),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // We extract sectionCounts for the FAB directly from provider inside another Consumer 
          // or we can pass it down. Wait, we can't extract it easily outside _buildShopTab unless we compute it.
          // Let's compute it quickly for the FAB
          Consumer<StoreProvider>(
            builder: (context, provider, child) {
              if (provider.currentStore == null || provider.isLoadingProducts) return const SizedBox.shrink();
              if (_tabController.index != 0) return const SizedBox.shrink(); // Only show on Shop tab
              
              final Map<String, int> sectionCounts = {};
              for (var product in provider.filteredProducts) {
                if (product.subCategoryIds.isEmpty) {
                  sectionCounts['Other Delights'] = (sectionCounts['Other Delights'] ?? 0) + 1;
                } else {
                  for (var subId in product.subCategoryIds) {
                    final subName = provider.availableSubcategories[subId]?['name'] ?? "Other Delights";
                    sectionCounts[subName] = (sectionCounts[subName] ?? 0) + 1;
                  }
                }
              }
              return StoreMenuFab(
                sectionCounts: sectionCounts,
                onSubcategorySelected: _scrollToSection,
              );
            },
          ),
          const FloatingCartBar(),
        ],
      ),
    );
  }

  Widget _buildShopTab(BuildContext context, StoreProvider provider) {
    if (provider.isLoadingProducts) {
      return CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyCategoryDelegate(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  DynamicCategoryChips(),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 40, height: 20, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(height: 12),
                              Container(width: double.infinity, height: 16, color: Colors.grey.shade100),
                              const SizedBox(height: 6),
                              Container(width: 150, height: 16, color: Colors.grey.shade100),
                              const SizedBox(height: 16),
                              Container(width: 80, height: 24, color: Colors.grey.shade100),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 160,
                          height: 184,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: 4,
              ),
            ),
          ),
        ],
      );
    }

    final products = provider.filteredProducts;

    // Group products by subcategory for the premium Accordion/List layout
    _groupedProducts = {};
    
    // 1. Inject Virtual Categories (Bestsellers & Offers) ONLY on the 'All' tab
    if (provider.selectedCategory == "All") {
      final bestSellers = products.where((p) => p.isTrending || p.rating >= 4.5 || p.reviewsCount >= 10).toList();
      if (bestSellers.isNotEmpty) {
        _groupedProducts["Bestsellers"] = bestSellers.take(5).toList();
      }

      final offers = products.where((p) => p.originalPrice > p.price).toList();
      if (offers.isNotEmpty) {
        _groupedProducts["Discounts"] = offers.toList(); // Show all discounted products
      }
    }

    // 2. Group standard products
    for (var product in products) {
      if (product.subCategoryIds.isEmpty) {
        _groupedProducts.putIfAbsent("Other Delights", () => []).add(product);
      } else {
        for (var subId in product.subCategoryIds) {
          final subName = provider.availableSubcategories[subId]?['name'] ?? "Other Delights";
          _groupedProducts.putIfAbsent(subName, () => []).add(product);
        }
      }
    }
    
    // 3. Sort sections with virtual categories at the top
    int getRank(String key) {
      if (key == "Bestsellers") return 0;
      if (key == "Discounts") return 1;
      if (key == "Other Delights") return 999;
      return 2;
    }

    _sortedKeys = _groupedProducts.keys.toList()..sort((a, b) {
      final rankA = getRank(a);
      final rankB = getRank(b);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.compareTo(b);
    });

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyCategoryDelegate(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                DynamicCategoryChips(),
                SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dining_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    "No items match your cravings.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          )
        else
          ..._sortedKeys.expand((sectionName) {
            final sectionProducts = _groupedProducts[sectionName]!;
            final isCollapsed = _collapsedSections.contains(sectionName);

            return [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 56.0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isCollapsed) {
                            _collapsedSections.remove(sectionName);
                          } else {
                            _collapsedSections.add(sectionName);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$sectionName (${sectionProducts.length})",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            AnimatedRotation(
                              turns: isCollapsed ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.keyboard_arrow_up, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!isCollapsed)
                SliverFixedExtentList(
                  itemExtent: 224.0, // Pre-calculated exact height for perfect scrolling
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return StoreProductListItem(product: sectionProducts[index]);
                    },
                    childCount: sectionProducts.length,
                  ),
                ),
            ];
          }),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 120), // Ensures last item isn't blocked by FAB
            child: Column(
              children: [
                Icon(Icons.volunteer_activism_outlined, color: Colors.grey.shade300, size: 36),
                const SizedBox(height: 12),
                Text(
                  "HAPPY TO SERVE YOU",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "From our kitchen to your table 🍲",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
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

class _StickyCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyCategoryDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // We add a subtle padding only at the top of the content so it looks balanced,
    // but without any structural gap. The status bar is automatically handled by SafeArea if needed.
    return Container(
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: shrinkOffset > 0 || overlapsContent
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => 140.0;

  @override
  double get minExtent => 140.0;

  @override
  bool shouldRebuild(covariant _StickyCategoryDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
