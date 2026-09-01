import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/theme/app_colors.dart';
import 'home/home_feed_view.dart';
import 'categories/categories_screen.dart';
import '../presentation/screens/following/following_screen.dart';
import '../presentation/screens/orders/orders_list_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/widgets/cart/floating_cart_bar.dart';
import 'dev/seeder_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  static final GlobalKey<CustomerHomeScreenState> globalKey =
      GlobalKey<CustomerHomeScreenState>();

  @override
  State<CustomerHomeScreen> createState() => CustomerHomeScreenState();
}

class CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _pages = [
    const HomeFeedView(),
    const CategoriesScreen(),
    const FollowingScreen(),
    const OrdersListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: _pages),
            if (_currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2)
              const FloatingCartBar(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.textSecondary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryGreen,
            unselectedItemColor: AppColors.textSecondary.withOpacity(0.5),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home_rounded),
                label: 'bottom_nav.home'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.grid_view_outlined),
                activeIcon: const Icon(Icons.grid_view_rounded),
                label: 'bottom_nav.categories'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.favorite_border_rounded),
                activeIcon: const Icon(Icons.favorite_rounded),
                label: 'bottom_nav.following'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.receipt_long_outlined),
                activeIcon: const Icon(Icons.receipt_long_rounded),
                label: 'bottom_nav.orders'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline_rounded),
                activeIcon: const Icon(Icons.person_rounded),
                label: 'bottom_nav.profile'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
