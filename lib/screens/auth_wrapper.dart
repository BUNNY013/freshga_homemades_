import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/customer_provider.dart';
import 'customer_home_screen.dart';
import 'login_screen.dart';
import 'location_setup_screen.dart'; // Will create this next

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is authenticated, now check customer profile
          return Consumer<CustomerProvider>(
            builder: (context, customerProvider, child) {
              if (customerProvider.isLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final customer = customerProvider.currentCustomer;
              if (customer != null && customer.selectedLocation == null) {
                return const LocationSetupScreen();
              }

              return const CustomerHomeScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
