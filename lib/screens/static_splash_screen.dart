import 'package:flutter/material.dart';

class StaticSplashScreen extends StatelessWidget {
  const StaticSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF6CBF43), // Exact green from image
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'FreshGa',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Homemades',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
