import 'package:flutter/material.dart';
import '../../models/store_model.dart';
import 'section_title.dart';
import 'store_card.dart';

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
        SectionTitle(title: title, onSeeAll: () {}),
        const SizedBox(height: 16),
        SizedBox(
          height: 190, // Adjusted for the mini StoreCard design
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
