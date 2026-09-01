import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/customer_provider.dart';
import 'store_card.dart';
import '../../presentation/screens/store/store_list_screen.dart';
import 'section_title.dart';
import 'loading_shimmers.dart';
import '../../core/theme/app_colors.dart';

class LocalBrandsSection extends StatefulWidget {
  final String title;

  const LocalBrandsSection({super.key, required this.title});

  @override
  State<LocalBrandsSection> createState() => _LocalBrandsSectionState();
}

class _LocalBrandsSectionState extends State<LocalBrandsSection> {
  String _lastCity = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndLoadLocation();
  }

  void _checkAndLoadLocation() {
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: true,
    );
    final customer = customerProvider.currentCustomer;

    if (customer != null && customer.selectedLocation != null) {
      final city = customer.city ?? '';
      final state = customer.state ?? '';

      if (city.isNotEmpty && city != _lastCity) {
        _lastCity = city;
        // Schedule microtask to avoid building state issues
        Future.microtask(() {
          if (mounted) {
            Provider.of<StoreProvider>(
              context,
              listen: false,
            ).loadLocalStores(city, state);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingLocal) {
          return const SectionShimmer();
        }

        if (provider.localStores.isEmpty) {
          return const SizedBox(); // Hide if no local brands found
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
                      stores: provider.localStores,
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
                itemCount: provider.localStores.length,
                itemBuilder: (context, index) {
                  return StoreCard(store: provider.localStores[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
