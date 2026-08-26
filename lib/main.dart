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
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'presentation/screens/store/store_screen.dart';
import 'presentation/screens/product/product_details_screen.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    // Check initial link if app was closed
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        // Add a tiny delay to allow the app to initialize before pushing
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      debugPrint("Failed to get initial deep link: $e");
    }

    // Listen to incoming links when app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Deep link stream error: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.pathSegments.isNotEmpty) {
      final String type = uri.pathSegments[0];
      if (uri.pathSegments.length > 1) {
        final String id = uri.pathSegments[1];
        
        if (type == 'store') {
          globalNavigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => StoreScreen(storeId: id))
          );
        } else if (type == 'product') {
          globalNavigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: id))
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

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

                if (network.isSlow && network.isOnline) {
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          color: Colors.orange.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_tethering_error_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Slow internet connection',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
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
