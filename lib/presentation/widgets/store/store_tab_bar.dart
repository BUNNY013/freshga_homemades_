import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StoreTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  StoreTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          tabBar,
          Container(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(StoreTabBarDelegate oldDelegate) {
    return false;
  }
}
