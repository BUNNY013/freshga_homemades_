import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store_model.dart';
import '../../../widgets/home/store_card.dart';
import '../cart/cart_screen.dart';

class StoreListScreen extends StatelessWidget {
  final String title;
  final List<StoreModel> stores;

  const StoreListScreen({super.key, required this.title, required this.stores});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          ),
        ],
      ),
      body: stores.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    "No stores found",
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                return StoreCard(store: stores[index], isFullWidth: true);
              },
            ),
    );
  }
}
