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

    _isLoading = true;
    notifyListeners();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final results = await _searchService.getLiveSuggestions(query);
      _productSuggestions = (results['products'] as List<dynamic>).cast<ProductModel>();
      _storeSuggestions = (results['stores'] as List<dynamic>).cast<StoreModel>();
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
      final futures = await Future.wait([
        _searchService.searchProducts(query),
        _searchService.searchStores(query),
      ]);
      
      _searchResultsProducts = futures[0] as List<ProductModel>;
      _searchResultsStores = futures[1] as List<StoreModel>;
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
