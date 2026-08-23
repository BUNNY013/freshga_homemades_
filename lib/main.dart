import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'providers/home_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/category_provider.dart';
import 'providers/store_provider.dart';
import 'providers/product_provider.dart';
import 'providers/collection_provider.dart';
import 'providers/search_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/following_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/network_provider.dart';
import 'providers/maintenance_provider.dart';
import 'screens/no_internet_screen.dart';
import 'screens/maintenance_mode_screen.dart';
import 'providers/update_provider.dart';
import 'screens/force_update_screen.dart';
import 'screens/soft_update_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
          Locale('te')
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NetworkProvider()),
          ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
          ChangeNotifierProvider(create: (_) => UpdateProvider()),
          Provider<AuthService>(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProxyProvider<CustomerProvider, StoreProvider>(
          create: (_) => StoreProvider(),
          update: (_, customer, store) => store!..updateCustomerState(customer.currentCustomer?.state),
        ),
        ChangeNotifierProxyProvider<CustomerProvider, ProductProvider>(
          create: (_) => ProductProvider(),
          update: (_, customer, product) => product!..updateCustomerState(customer.currentCustomer?.state),
        ),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FollowingProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: const MyApp(),
    ),
      ),
  );
}

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'FreshGa HomeMades',
      theme: AppTheme.lightTheme,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            Consumer3<NetworkProvider, MaintenanceProvider, UpdateProvider>(
              builder: (context, network, maintenance, update, _) {
                if (!network.isOnline) {
                  return Positioned.fill(
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: MediaQuery(
                        data: MediaQueryData.fromView(View.of(context)),
                        child: Theme(
                          data: AppTheme.lightTheme,
                          child: const NoInternetScreen(),
                        ),
                      ),
                    ),
                  );
                }
                
                if (update.isForceUpdate) {
                  return Positioned.fill(
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: MediaQuery(
                        data: MediaQueryData.fromView(View.of(context)),
                        child: Theme(
                          data: AppTheme.lightTheme,
                          child: const ForceUpdateScreen(),
                        ),
                      ),
                    ),
                  );
                }
                
                if (maintenance.isMaintenanceMode) {
                  return Positioned.fill(
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: MediaQuery(
                        data: MediaQueryData.fromView(View.of(context)),
                        child: Theme(
                          data: AppTheme.lightTheme,
                          child: const MaintenanceModeScreen(),
                        ),
                      ),
                    ),
                  );
                }

                if (update.isSoftUpdate) {
                  return Positioned.fill(
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: MediaQuery(
                        data: MediaQueryData.fromView(View.of(context)),
                        child: Theme(
                          data: AppTheme.lightTheme,
                          child: const SoftUpdateOverlay(),
                        ),
                      ),
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
      home: const SplashScreen(),
    );
  }
}
