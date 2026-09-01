import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';

class StoreTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  StoreTabBarDelegate(this.tabController);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryGreen,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: "store.shop".tr()),
              Tab(text: "store.about".tr()),
            ],
          ),
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 49.0;

  @override
  double get minExtent => 49.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
