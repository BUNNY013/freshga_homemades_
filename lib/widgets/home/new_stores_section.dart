import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import 'store_card.dart';
import '../../presentation/screens/store/store_list_screen.dart';
import 'section_title.dart';
import 'loading_shimmers.dart';

class NewStoresSection extends StatefulWidget {
  final String title;

  const NewStoresSection({super.key, required this.title});

  @override
  State<NewStoresSection> createState() => _NewStoresSectionState();
}

class _NewStoresSectionState extends State<NewStoresSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<StoreProvider>(context, listen: false).loadNewStores();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingNew) {
          return const SectionShimmer();
        }

        if (provider.newStores.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: widget.title,
              onSeeAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreListScreen(
                      title: widget.title,
                      stores: provider.newStores,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: provider.newStores.length,
                itemBuilder: (context, index) {
                  return StoreCard(store: provider.newStores[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
