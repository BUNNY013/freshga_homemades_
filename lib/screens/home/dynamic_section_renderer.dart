import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/home_section_model.dart';
import '../../providers/banner_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/collection_provider.dart';
import '../../widgets/home/hero_banner_carousel.dart';
import '../../widgets/home/categories_section.dart';
import '../../widgets/home/featured_stores_section.dart';
import '../../widgets/home/following_stores_section.dart';
import '../../widgets/home/store_updates_section.dart';
import '../../widgets/home/local_brands_section.dart';
import '../../widgets/home/new_stores_section.dart';
import '../../widgets/home/collections_section.dart';
import '../../widgets/home/trust_strip_section.dart';
import '../../widgets/home/loading_shimmers.dart';
import '../categories/categories_screen.dart';
import '../categories/category_discovery_screen.dart';
import '../customer_home_screen.dart';

class DynamicSectionRenderer extends StatelessWidget {
  final HomeSectionModel section;

  const DynamicSectionRenderer({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    if (!section.isActive) return const SizedBox();

    switch (section.type) {
      case 'heroBanner':
        return Consumer<BannerProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) return const SectionShimmer();
            return HeroBannerCarousel(banners: provider.banners);
          },
        );
      case 'categories':
        return Consumer<CategoryProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) return const SectionShimmer();
            return CategoriesSection(
              categories: provider.categories,
              title: section.title.tr(),
              onViewAll: () {
                CustomerHomeScreen.globalKey.currentState?.switchTab(1);
              },
              onCategoryTap: (category) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryDiscoveryScreen(category: category),
                  ),
                );
              },
            );
          },
        );
      case 'followingStores':
        return FollowingStoresSection(title: section.title);
      case 'storeUpdates':
        return StoreUpdatesSection(title: section.title);
      case 'localBrands':
        return LocalBrandsSection(title: section.title);
      case 'newStores':
        return NewStoresSection(title: section.title);
      case 'featuredStores':
        return Consumer<StoreProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) return const SectionShimmer();
            return FeaturedStoresSection(
              stores: provider.stores,
              title: section.title,
            );
          },
        );
      case 'collections':
        return Consumer<CollectionProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) return const SectionShimmer();
            return CollectionsSection(
              collections: provider.collections,
              title: section.title,
            );
          },
        );
      case 'trustStrip':
        return const TrustStripSection();
      default:
        return const SizedBox();
    }
  }
}
