import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/following_provider.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Stores You Follow',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
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
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
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
                          
                          // Mock data for UI fidelity based on the image
                          final storeNameStr = store['storeName'] ?? 'Store';
                          final username = '@${storeNameStr.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
                          final productsCount = 18 + (index * 7) % 50;
                          final locations = ['Hyderabad, TS', 'Vijayawada, AP', 'Guntur, AP', 'Ongole, AP', 'Bengaluru, KA', 'Kochi, KL', 'Chennai, TN', 'Mumbai, MH'];
                          final location = locations[index % locations.length];
                          
                          // Mock badges matching the image
                          String? badgeText;
                          Color? badgeColor;
                          if (index == 0 || index == 2 || index == 5) {
                            badgeText = 'New';
                            badgeColor = AppColors.primaryGreen;
                          } else if (index == 1) {
                            badgeText = 'Offer';
                            badgeColor = const Color(0xFFF43F5E); // Premium Pink
                          } else if (index == 3) {
                            badgeText = 'Restock';
                            badgeColor = const Color(0xFFE67E22); // Orange
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoreScreen(storeId: store['storeId']),
                                ),
                              );
                            },
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  // Avatar with colored ring
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: badgeColor?.withOpacity(0.4) ?? Colors.grey.shade200, 
                                        width: 1.5
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.grey[100],
                                      backgroundImage: (store['storeLogo'] != null && store['storeLogo'].toString().isNotEmpty)
                                          ? CachedNetworkImageProvider(store['storeLogo'])
                                          : const CachedNetworkImageProvider('https://images.unsplash.com/photo-1556910103-1c02745a872f?w=100&h=100&fit=crop'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Middle Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          storeNameStr,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$productsCount Products  •  $location',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Right side (Badge + Arrow)
                                  if (badgeText != null && badgeColor != null)
                                    Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: badgeColor,
                                          fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                                        ),
                                      ),
                                    ),
                                    
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                                ],
                              ),
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
