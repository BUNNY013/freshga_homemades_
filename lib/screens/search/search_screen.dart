import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/search_provider.dart';
import '../../widgets/search/suggestion_tile.dart';
import '../../widgets/search/recent_search_tile.dart';
import '../../widgets/search/search_loading_shimmer.dart';
import 'search_results_screen.dart';

import '../../presentation/screens/store/store_screen.dart';
import '../../presentation/screens/product/product_details_screen.dart';
import '../../presentation/widgets/cart/floating_cart_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus the search field when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query, SearchProvider provider) {
    if (query.trim().isEmpty) return;
    provider.performFullSearch(query);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchResultsScreen()),
    );
  }

  Widget _buildQuickCategory(String text) {
    return InkWell(
      onTap: () {
        _searchController.text = text;
        _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
        final provider = context.read<SearchProvider>();
        provider.onSearchQueryChanged(text);
        _onSearchSubmitted(text, provider);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
    );
  }

  Widget _buildTrendingChip(String text) {
    // Extract actual search term without emoji (assuming emoji is at index 0 followed by space)
    final searchTerm = text.contains(' ') ? text.substring(text.indexOf(' ') + 1) : text;
    
    return InkWell(
      onTap: () {
        _searchController.text = searchTerm;
        _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
        final provider = context.read<SearchProvider>();
        provider.onSearchQueryChanged(searchTerm);
        _onSearchSubmitted(searchTerm, provider);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom Search AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
                              child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300, width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _focusNode,
                                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                                      decoration: const InputDecoration(
                                        hintText: "Search products, stores...",
                                        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (val) {
                                        searchProvider.onSearchQueryChanged(val);
                                      },
                                      onSubmitted: (val) => _onSearchSubmitted(val, searchProvider),
                                      textInputAction: TextInputAction.search,
                                    ),
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    InkWell(
                                      onTap: () {
                                        _searchController.clear();
                                        searchProvider.clearSearch();
                                        _focusNode.requestFocus();
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Icon(Icons.cancel, color: Colors.grey, size: 18),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content Area
                    Expanded(
                      child: _buildContent(searchProvider),
                    ),
                  ],
                );
              },
            ),
          ),
          const FloatingCartBar(),
        ],
      ),
    );
  }

  Widget _buildContent(SearchProvider searchProvider) {
    if (searchProvider.isLoading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text("Suggestions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          ),
          SearchLoadingShimmer(),
        ],
      );
    }

    if (_searchController.text.isEmpty) {
      return ListView(
        children: [
          // Recent Searches (if any)
          if (searchProvider.recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Searches", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                  InkWell(
                    onTap: () => searchProvider.clearRecentSearches(),
                    child: const Text("Clear all", style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            ...searchProvider.recentSearches.map((query) => RecentSearchTile(
              query: query,
              onTap: () {
                _searchController.text = query;
                _searchController.selection = TextSelection.fromPosition(TextPosition(offset: query.length));
                _onSearchSubmitted(query, searchProvider);
              },
              onRemove: () => searchProvider.removeRecentSearch(query),
            )),
            const Divider(height: 32, thickness: 6, color: Color(0xFFF5F5F5)), // Section separator
          ],


        ],
      );
    }

    // Show Live Suggestions
    if (searchProvider.productSuggestions.isEmpty && searchProvider.storeSuggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Colors.black12),
            const SizedBox(height: 16),
            Text("No results found for '${_searchController.text}'", style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (searchProvider.productSuggestions.isNotEmpty || searchProvider.storeSuggestions.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text("Suggestions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          ),
        
        // Stores (Accounts) appear first (Instagram-style)
        ...searchProvider.storeSuggestions.map((s) => SuggestionTile(
          title: s.name,
          subtitle: "@${s.storeSlug}",
          imageUrl: s.logoUrl,
          isStore: true,
          onTap: () {
            // Save search to history but navigate directly to store
            searchProvider.saveRecentSearch("@${s.storeSlug}");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StoreScreen(storeId: s.id)),
            );
          },
        )),
        
        // Products appear below stores
        ...searchProvider.productSuggestions.map((p) => SuggestionTile(
          title: p.name,
          subtitle: p.storeName,
          imageUrl: p.images.isNotEmpty ? p.images.first : null,
          isStore: false,
          onTap: () {
            // Save search to history but navigate directly to product
            searchProvider.saveRecentSearch(p.name);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProductDetailsScreen(productId: p.id)),
            );
          },
        )),

        const SizedBox(height: 16),
        // View All Results button
        InkWell(
          onTap: () => _onSearchSubmitted(_searchController.text, searchProvider),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                const Text(
                  "View all results for ",
                  style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '"${_searchController.text}"',
                  style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryGreen, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
