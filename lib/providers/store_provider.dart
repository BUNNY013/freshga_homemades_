import 'package:flutter/foundation.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import '../services/store_service.dart';

enum StoreSortType { bestSelling, newest, priceLowHigh, priceHighLow }

class StoreProvider with ChangeNotifier {
  final StoreService _service = StoreService();
  
  // Individual Store State
  StoreModel? _currentStore;
  bool _isLoadingStore = false;
  String? _storeError;

  StoreModel? get currentStore => _currentStore;
  bool get isLoadingStore => _isLoadingStore;
  String? get storeError => _storeError;

  // Store Products
  List<ProductModel> _allStoreProducts = [];
  bool _isLoadingProducts = false;
  
  List<ProductModel> get allStoreProducts => _allStoreProducts;
  bool get isLoadingProducts => _isLoadingProducts;

  // Home Screen Featured Stores State
  List<StoreModel> _stores = [];
  bool _isLoadingFeatured = false;
  
  List<StoreModel> get stores => _stores;
  bool get isLoading => _isLoadingFeatured;

  // Dynamic Categories extracted from products
  // Format: categoryId -> categoryName
  final Map<String, String> _availableCategories = {};
  
  // Format: subCategoryId -> { 'id': subCategoryId, 'name': name, 'categoryId': parentId }
  final Map<String, Map<String, dynamic>> _availableSubcategories = {};

  Map<String, String> get availableCategories => _availableCategories;
  Map<String, Map<String, dynamic>> get availableSubcategories => _availableSubcategories;

  // Filter States
  String _searchQuery = "";
  String _selectedCategory = "All";
  String _selectedSubcategory = "All";
  StoreSortType _sortType = StoreSortType.bestSelling;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedSubcategory => _selectedSubcategory;
  StoreSortType get sortType => _sortType;

  // Follow State (Optimistic)
  bool _isFollowing = false;
  bool get isFollowing => _isFollowing;

  // Computed Filtered Products
  List<ProductModel> get filteredProducts {
    List<ProductModel> result = List.from(_allStoreProducts);

    // 1. Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(query) || 
               p.searchKeywords.any((k) => k.contains(query));
      }).toList();
    }

    // 2. Category Filter
    if (_selectedCategory != "All") {
      result = result.where((p) => p.categoryId == _selectedCategory).toList();
    }

    // 3. Subcategory Filter
    if (_selectedSubcategory != "All") {
      result = result.where((p) => p.subCategoryIds.contains(_selectedSubcategory)).toList();
    }

    // 4. Sorting
    switch (_sortType) {
      case StoreSortType.bestSelling:
        result.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount)); // proxy for orders
        break;
      case StoreSortType.newest:
        // We don't have createdAt in ProductModel currently, fallback to ID sorting or add createdAt to model
        result.sort((a, b) => b.id.compareTo(a.id));
        break;
      case StoreSortType.priceLowHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case StoreSortType.priceHighLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
    }

    return result;
  }

  Future<void> loadStoreData(String storeId) async {
    _isLoadingStore = true;
    _storeError = null;
    _currentStore = null;
    _isFollowing = false;
    _searchQuery = "";
    _selectedCategory = "All";
    _selectedSubcategory = "All";
    _sortType = StoreSortType.bestSelling;
    notifyListeners();

    try {
      _currentStore = await _service.getStore(storeId);
      if (_currentStore == null) {
        _storeError = "Store not found";
      } else {
        await loadAllStoreProducts(storeId);
      }
    } catch (e) {
      _storeError = e.toString();
    } finally {
      _isLoadingStore = false;
      notifyListeners();
    }
  }

  Future<void> loadAllStoreProducts(String storeId) async {
    _isLoadingProducts = true;
    notifyListeners();

    try {
      _allStoreProducts = await _service.getAllStoreProducts(storeId);
      await _extractDynamicCategories();
    } catch (e) {
      debugPrint("Error loading store products: $e");
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> loadFeaturedStores() async {
    _isLoadingFeatured = true;
    notifyListeners();

    try {
      _stores = await _service.getFeaturedStores();
    } catch (e) {
      debugPrint("Error loading featured stores: $e");
    } finally {
      _isLoadingFeatured = false;
      notifyListeners();
    }
  }

  Future<void> _extractDynamicCategories() async {
    _availableCategories.clear();
    _availableSubcategories.clear();

    Set<String> subcatIdsToFetch = {};

    for (var p in _allStoreProducts) {
      if (p.categoryId.isNotEmpty && p.categoryName.isNotEmpty) {
        _availableCategories[p.categoryId] = p.categoryName;
      }
      for (var subId in p.subCategoryIds) {
        subcatIdsToFetch.add(subId);
      }
    }

    // Fetch names for all collected subcategories
    if (subcatIdsToFetch.isNotEmpty) {
      var subcats = await _service.getSubcategoriesByIds(subcatIdsToFetch.toList());
      for (var subData in subcats) {
        if (subData.containsKey('subCategoryId') && subData.containsKey('name') && subData.containsKey('categoryId')) {
          _availableSubcategories[subData['subCategoryId']] = {
            'id': subData['subCategoryId'],
            'name': subData['name'],
            'categoryId': subData['categoryId']
          };
        }
      }
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String categoryId) {
    if (_selectedCategory == categoryId) return;
    _selectedCategory = categoryId;
    _selectedSubcategory = "All"; // Reset subcategory when category changes
    notifyListeners();
  }

  void setSubcategory(String subcategoryId) {
    if (_selectedSubcategory == subcategoryId) return;
    _selectedSubcategory = subcategoryId;
    notifyListeners();
  }

  void setSortType(StoreSortType sortType) {
    if (_sortType == sortType) return;
    _sortType = sortType;
    notifyListeners();
  }

  void toggleFollow(String userId) {
    if (_currentStore == null) return;
    
    _isFollowing = !_isFollowing;
    notifyListeners();

    if (_isFollowing) {
      _service.followStore(_currentStore!.id, userId);
    } else {
      _service.unfollowStore(_currentStore!.id, userId);
    }
  }
}
