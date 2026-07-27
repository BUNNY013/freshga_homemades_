import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
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
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FreshGa HomeMades',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
