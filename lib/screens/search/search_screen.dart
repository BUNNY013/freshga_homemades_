import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/search_provider.dart';
import '../../widgets/search/suggestion_tile.dart';
import '../../widgets/search/recent_search_tile.dart';
import '../../widgets/search/search_loading_shimmer.dart';
import 'search_results_screen.dart';

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
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.grey.shade200),
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
      // Show Recent Searches
      if (searchProvider.recentSearches.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, size: 64, color: Colors.black12),
              SizedBox(height: 16),
              Text("Search for homemade goodness", style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        );
      }

      return ListView(
        children: [
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
        
        // Products
        ...searchProvider.productSuggestions.map((p) => SuggestionTile(
          title: p.name,
          isStore: false,
          onTap: () {
            _searchController.text = p.name;
            _onSearchSubmitted(p.name, searchProvider);
          },
        )),
        
        // Stores
        ...searchProvider.storeSuggestions.map((s) => SuggestionTile(
          title: s.name,
          isStore: true,
          onTap: () {
            _searchController.text = s.name;
            _onSearchSubmitted(s.name, searchProvider);
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
