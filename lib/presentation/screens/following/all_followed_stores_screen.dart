import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/following_provider.dart';
import '../../widgets/store/follow_button.dart';
import '../store/store_screen.dart';

class AllFollowedStoresScreen extends StatefulWidget {
  const AllFollowedStoresScreen({super.key});

  @override
  State<AllFollowedStoresScreen> createState() => _AllFollowedStoresScreenState();
}

class _AllFollowedStoresScreenState extends State<AllFollowedStoresScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Stores You Follow',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<FollowingProvider>(
        builder: (context, provider, child) {
          final stores = provider.followingStoresData.where((s) {
            final name = (s['storeName'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search followed stores...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Store List
              Expanded(
                child: stores.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? "You aren't following any stores." : "No stores found.",
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: stores.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 24),
                        itemBuilder: (context, index) {
                          final store = stores[index];
                          final isFollowing = provider.isFollowing(store['storeId']);
                          
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoreScreen(storeId: store['storeId']),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: (store['storeLogo'] != null && store['storeLogo'].toString().isNotEmpty)
                                      ? CachedNetworkImageProvider(store['storeLogo'])
                                      : null,
                                  child: (store['storeLogo'] == null || store['storeLogo'].toString().isEmpty)
                                      ? const Icon(Icons.store, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        store['storeName'] ?? 'Store',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Followed recently',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Unfollow Button
                                FollowButton(
                                  storeId: store['storeId'],
                                  storeName: store['storeName'] ?? 'Store',
                                  storeLogo: store['storeLogo']?.toString() ?? '',
                                  isCompact: true,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
