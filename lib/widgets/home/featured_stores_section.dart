import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import 'section_title.dart';
import 'store_card.dart';
import '../../presentation/screens/store/store_list_screen.dart';

class FeaturedStoresSection extends StatelessWidget {
  final List<StoreModel> stores;
  final String title;

  const FeaturedStoresSection({super.key, required this.stores, required this.title});

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: title, 
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreListScreen(
                  title: title,
                  stores: stores,
                ),
              ),
            );
          }
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250, // Adjusted for the compact StoreCard design
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: stores.length,
            itemBuilder: (context, index) => StoreCard(store: stores[index]),
          ),
        ),
      ],
    );
  }
}
