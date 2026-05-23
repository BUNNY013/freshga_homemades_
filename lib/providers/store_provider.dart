import 'package:flutter/foundation.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import '../services/store_service.dart';

class StoreProvider with ChangeNotifier {
  final StoreService _service = StoreService();
  
  // Featured Stores
  List<StoreModel> _stores = [];
  bool _isLoading = false;

  List<StoreModel> get stores => _stores;
  bool get isLoading => _isLoading;

  // Individual Store State
  StoreModel? _currentStore;
  bool _isLoadingStore = false;
  String? _storeError;

  StoreModel? get currentStore => _currentStore;
  bool get isLoadingStore => _isLoadingStore;
  String? get storeError => _storeError;

  // Store Products
  List<ProductModel> _storeProducts = [];
  bool _isLoadingProducts = false;
  bool _hasMoreProducts = true;
  
  List<ProductModel> get storeProducts => _storeProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get hasMoreProducts => _hasMoreProducts;

  // Featured Products
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> get featuredProducts => _featuredProducts;

  // Follow State (Optimistic)
  bool _isFollowing = false;
  bool get isFollowing => _isFollowing;

  Future<void> loadFeaturedStores() async {
    _isLoading = true;
    notifyListeners();
    try {
      _stores = await _service.getFeaturedStores();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStoreData(String storeId) async {
    _isLoadingStore = true;
    _storeError = null;
    _currentStore = null;
    _isFollowing = false; // Mocking initial state
    notifyListeners();

    try {
      _currentStore = await _service.getStore(storeId);
      if (_currentStore == null) {
        _storeError = "Store not found";
      } else {
        // Load featured products alongside
        _featuredProducts = await _service.getFeaturedProducts(storeId);
        // Load initial products
        await loadStoreProducts(storeId, isRefresh: true);
      }
    } catch (e) {
      _storeError = e.toString();
    } finally {
      _isLoadingStore = false;
      notifyListeners();
    }
  }

  Future<void> loadStoreProducts(String storeId, {bool isRefresh = false}) async {
    if (isRefresh) {
      _storeProducts = [];
      _hasMoreProducts = true;
    }

    if (!_hasMoreProducts || _isLoadingProducts) return;

    _isLoadingProducts = true;
    notifyListeners();

    try {
      // In a real app, you'd track the last document for pagination.
      // For simplicity in this demo, we'll just fetch normally if not paginating with a cursor yet.
      final newProducts = await _service.getStoreProducts(storeId);
      
      if (newProducts.isEmpty) {
        _hasMoreProducts = false;
      } else {
        _storeProducts.addAll(newProducts);
        if (newProducts.length < 20) {
          _hasMoreProducts = false;
        }
      }
    } catch (e) {
      debugPrint("Error loading store products: $e");
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
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
