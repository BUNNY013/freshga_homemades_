import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/search_service.dart';
import '../models/product_model.dart';
import '../models/store_model.dart';

class SearchProvider with ChangeNotifier {
  final SearchService _searchService = SearchService();
  Timer? _debounce;
  static const String _recentSearchesKey = 'recent_searches_key';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<String> _recentSearches = [];
  List<String> get recentSearches => _recentSearches;

  List<ProductModel> _productSuggestions = [];
  List<ProductModel> get productSuggestions => _productSuggestions;

  List<StoreModel> _storeSuggestions = [];
  List<StoreModel> get storeSuggestions => _storeSuggestions;

  // Full search results
  List<ProductModel> _searchResultsProducts = [];
  List<ProductModel> get searchResultsProducts => _searchResultsProducts;

  List<StoreModel> _searchResultsStores = [];
  List<StoreModel> get searchResultsStores => _searchResultsStores;

  SearchProvider() {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    notifyListeners();
  }

  Future<void> saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final formattedQuery = query.trim();
    // Remove if exists to push to front
    _recentSearches.removeWhere((q) => q.toLowerCase() == formattedQuery.toLowerCase());
    
    _recentSearches.insert(0, formattedQuery);
    
    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
    notifyListeners();
  }

  Future<void> removeRecentSearch(String query) async {
    _recentSearches.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    notifyListeners();
  }

  void onSearchQueryChanged(String query) {
    _searchQuery = query;
    
    if (query.trim().isEmpty) {
      _productSuggestions = [];
      _storeSuggestions = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Only show the shimmer loader if we are starting from an empty state
    // This allows seamless replacement of old suggestions without layout flicker
    if (_productSuggestions.isEmpty && _storeSuggestions.isEmpty) {
      _isLoading = true;
    }
    notifyListeners();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final bool isStoreSearch = query.trim().startsWith('@');
      final String cleanQuery = isStoreSearch ? query.trim().substring(1) : query;
      
      // If user typed "@" but nothing else, just return empty
      if (cleanQuery.trim().isEmpty) {
        _productSuggestions = [];
        _storeSuggestions = [];
        return;
      }

      final results = await _searchService.getLiveSuggestions(cleanQuery, isStoreSearch: isStoreSearch);
      
      List<StoreModel> rawStores = [];
      if (results['stores'] != null) {
        rawStores = (results['stores'] as List<dynamic>).cast<StoreModel>();
      }
      
      // Filter out paused stores
      _storeSuggestions = rawStores.where((s) => s.isActive).toList();
      
      if (isStoreSearch) {
        // If explicitly looking for accounts, don't show products
        _productSuggestions = [];
      } else {
        // Let's filter out products if their store is in the fetched stores and is paused.
        List<ProductModel> rawProducts = [];
        if (results['products'] != null) {
          rawProducts = (results['products'] as List<dynamic>).cast<ProductModel>();
        }
        final pausedStoreIdsInSuggestions = rawStores.where((s) => !s.isActive).map((s) => s.id).toSet();
        _productSuggestions = rawProducts.where((p) => !pausedStoreIdsInSuggestions.contains(p.storeId)).toList();
      }
    } catch (e) {
      print("Error fetching suggestions in provider: $e");
      _productSuggestions = [];
      _storeSuggestions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> performFullSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    _searchQuery = query;
    _isLoading = true;
    notifyListeners();
    
    await saveRecentSearch(query);

    try {
      final bool isStoreSearch = query.trim().startsWith('@');
      final String cleanQuery = isStoreSearch ? query.trim().substring(1) : query;
      
      // For full search, if they used @ we should ideally still search products, but maybe weight stores more.
      // We'll keep it simple: just use cleanQuery for both so results aren't completely empty if it was a mistake.
      final futures = await Future.wait([
        if (!isStoreSearch) _searchService.searchProducts(cleanQuery),
        _searchService.searchStores(cleanQuery, isStoreSearch: isStoreSearch),
      ]);
      
      List<ProductModel> products = isStoreSearch ? [] : futures[0] as List<ProductModel>;
      List<StoreModel> baselineStores = isStoreSearch ? futures[0] as List<StoreModel> : futures[1] as List<StoreModel>;

      // If we found products, make sure their parent stores are also displayed
      // in the "Stores" tab, even if the store name didn't explicitly match the query.
      final existingStoreIds = baselineStores.map((s) => s.id).toSet();
      final productStoreIds = products.map((p) => p.storeId).toSet();
      final missingStoreIds = productStoreIds.difference(existingStoreIds).toList();
      
      if (missingStoreIds.isNotEmpty) {
        final additionalStores = await _searchService.getStoresByIds(missingStoreIds);
        baselineStores.addAll(additionalStores);
      }
      
      // Filter out paused stores and their products
      final activeStoreIds = baselineStores.where((s) => s.isActive).map((s) => s.id).toSet();
      
      _searchResultsProducts = products.where((p) => activeStoreIds.contains(p.storeId)).toList();
      _searchResultsStores = baselineStores.where((s) => s.isActive).toList();
    } catch (e) {
       print("Error in performFullSearch: $e");
       _searchResultsProducts = [];
       _searchResultsStores = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearSearch() {
    _searchQuery = '';
    _productSuggestions = [];
    _storeSuggestions = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
