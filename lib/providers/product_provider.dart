import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/store_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _service = ProductService();
  StreamSubscription<DocumentSnapshot>? _productSubscription;

  @override
  void dispose() {
    _productSubscription?.cancel();
    super.dispose();
  }

  String? _customerState;
  void updateCustomerState(String? state) {
    _customerState = state;
  }

  List<ProductModel> _trendingProducts = [];
  bool _isLoadingTrending = false;

  List<ProductModel> get trendingProducts => _trendingProducts;
  bool get isLoadingTrending => _isLoadingTrending;

  // New states for product details
  ProductModel? _currentProduct;
  bool _isLoadingProduct = false;
  String? _productError;
  bool _isStoreActive = true;

  List<ProductModel> _similarProducts = [];
  bool _isLoadingSimilar = false;

  List<ProductModel> _suggestedProducts = [];
  bool _isLoadingSuggested = false;

  List<ProductModel> _storeProducts = [];
  bool _isLoadingStoreProducts = false;

  // Interaction states
  int _selectedVariantIndex = 0;
  int _quantity = 1;
  bool _isWishlisted = false;
  bool _isAddingToCart = false;

  ProductModel? get currentProduct => _currentProduct;
  bool get isLoadingProduct => _isLoadingProduct;
  String? get productError => _productError;
  bool get isStoreActive => _isStoreActive;
  List<ProductModel> get similarProducts => _similarProducts;
  bool get isLoadingSimilar => _isLoadingSimilar;
  List<ProductModel> get suggestedProducts => _suggestedProducts;
  bool get isLoadingSuggested => _isLoadingSuggested;
  List<ProductModel> get storeProducts => _storeProducts;
  bool get isLoadingStoreProducts => _isLoadingStoreProducts;

  int get selectedVariantIndex => _selectedVariantIndex;
  int get quantity => _quantity;
  bool get isWishlisted => _isWishlisted;
  bool get isAddingToCart => _isAddingToCart;

  List<ProductVariantModel> get variants => _currentProduct?.variants ?? [];

  double get currentVariantPrice {
    if (variants.isEmpty) return _currentProduct?.price ?? 0.0;
    if (_selectedVariantIndex >= variants.length)
      return _currentProduct?.price ?? 0.0;
    final variant = variants[_selectedVariantIndex];
    return variant.discountPrice > 0 ? variant.discountPrice : variant.price;
  }

  double get currentVariantOriginalPrice {
    if (variants.isEmpty) return _currentProduct?.originalPrice ?? 0.0;
    if (_selectedVariantIndex >= variants.length)
      return _currentProduct?.originalPrice ?? 0.0;
    return variants[_selectedVariantIndex].price;
  }

  // Discovery Feed State
  List<ProductModel> _allDiscoveryProducts = [];
  List<ProductModel> _discoveryProducts = [];
  bool _isLoadingDiscovery = false;
  bool _isPaginatingDiscovery = false;
  bool _hasMoreDiscovery = true;
  int _currentDiscoveryPage = 0;
  final int _discoveryPageSize = 6;

  List<ProductModel> get discoveryProducts => _discoveryProducts;
  bool get isLoadingDiscovery => _isLoadingDiscovery;
  bool get isPaginatingDiscovery => _isPaginatingDiscovery;
  bool get hasMoreDiscovery => _hasMoreDiscovery;

  Future<void> loadDiscoveryFeed({bool refresh = false}) async {
    if (refresh) {
      _hasMoreDiscovery = true;
      _discoveryProducts.clear();
      _allDiscoveryProducts.clear();
      _currentDiscoveryPage = 0;
    } else if (_discoveryProducts.isNotEmpty) {
      return; // Already loaded
    }

    _isLoadingDiscovery = true;
    notifyListeners();

    try {
      if (_allDiscoveryProducts.isEmpty) {
        // Fetch a large pool of products and shuffle them
        _allDiscoveryProducts = await _service.getRandomDiscoveryProducts(
          limit: 50,
          customerState: _customerState,
        );
      }

      _loadNextDiscoveryChunk();
    } catch (e) {
      debugPrint('Error loading discovery feed: $e');
    } finally {
      _isLoadingDiscovery = false;
      notifyListeners();
    }
  }

  void _loadNextDiscoveryChunk() {
    final startIndex = _currentDiscoveryPage * _discoveryPageSize;
    final endIndex = startIndex + _discoveryPageSize;

    if (startIndex >= _allDiscoveryProducts.length) {
      _hasMoreDiscovery = false;
      return;
    }

    final chunk = _allDiscoveryProducts.sublist(
      startIndex,
      endIndex > _allDiscoveryProducts.length
          ? _allDiscoveryProducts.length
          : endIndex,
    );

    _discoveryProducts.addAll(chunk);
    _currentDiscoveryPage++;

    if (endIndex >= _allDiscoveryProducts.length) {
      _hasMoreDiscovery = false;
    }
  }

  Future<void> loadMoreDiscoveryFeed() async {
    if (_isPaginatingDiscovery || !_hasMoreDiscovery) return;

    _isPaginatingDiscovery = true;
    notifyListeners();

    // Small delay to make pagination feel smooth
    await Future.delayed(const Duration(milliseconds: 500));

    _loadNextDiscoveryChunk();

    _isPaginatingDiscovery = false;
    notifyListeners();
  }

  Future<void> loadTrendingProducts() async {
    _isLoadingTrending = true;
    notifyListeners();
    try {
      _trendingProducts = await _service.getTrendingProducts(
        customerState: _customerState,
      );
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  Future<void> loadProductDetails(String productId) async {
    _isLoadingProduct = true;
    _currentProduct = null;
    _productError = null;
    _selectedVariantIndex = 0;
    _quantity = 1;
    notifyListeners();

    try {
      _currentProduct = await _service.getProduct(productId);
      if (_currentProduct != null) {
        // Set up real-time listener for the product
        _productSubscription?.cancel();
        _productSubscription = FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .snapshots()
            .listen((snapshot) {
              if (snapshot.exists && snapshot.data() != null) {
                _currentProduct = ProductModel.fromJson(
                  snapshot.data()!,
                  snapshot.id,
                );
                notifyListeners();
              }
            });

        try {
          final storeDoc = await FirebaseFirestore.instance
              .collection('stores')
              .doc(_currentProduct!.storeId)
              .get();
          final data = storeDoc.data();
          final bool isStoreSuspendedOrInactive =
              !(data?['isActive'] ?? true) ||
              ((data?['status'] ?? '').toString().toLowerCase() == 'suspended');

          if (isStoreSuspendedOrInactive) {
            _isStoreActive = false;
          } else {
            _isStoreActive = await StoreService().isStoreActive(
              _currentProduct!.storeId,
            );
          }
        } catch (e) {
          _isStoreActive = true;
        }

        // Fetch recommendations in parallel
        _fetchRecommendations(_currentProduct!);
      }
    } catch (e) {
      _productError = e.toString();
      debugPrint('Error loading product: $e');
    } finally {
      _isLoadingProduct = false;
      notifyListeners();
    }
  }

  Future<void> _fetchRecommendations(ProductModel product) async {
    _isLoadingSimilar = true;
    _isLoadingSuggested = true;
    _isLoadingStoreProducts = true;
    notifyListeners();

    try {
      final similarFuture = _service.getSimilarProducts(
        product,
        customerState: _customerState,
      );
      final suggestedFuture = _service.getSuggestedProducts(
        product,
        customerState: _customerState,
      );
      final storeProductsFuture = _service.getStoreProducts(
        product.storeId,
        excludeProductId: product.id,
      );

      final results = await Future.wait([
        similarFuture,
        suggestedFuture,
        storeProductsFuture,
      ]);

      _similarProducts = results[0];
      _suggestedProducts = results[1];
      _storeProducts = results[2];
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    } finally {
      _isLoadingSimilar = false;
      _isLoadingSuggested = false;
      _isLoadingStoreProducts = false;
      notifyListeners();
    }
  }

  void selectVariant(int index) {
    if (index >= 0 && index < variants.length) {
      _selectedVariantIndex = index;
      notifyListeners();
    }
  }

  void incrementQuantity() {
    if (_quantity < 10) {
      _quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity() {
    if (_quantity > 1) {
      _quantity--;
      notifyListeners();
    }
  }

  Future<void> toggleWishlist() async {
    if (_currentProduct == null) return;

    // Optimistic UI update
    _isWishlisted = !_isWishlisted;
    notifyListeners();

    try {
      await _service.toggleWishlist(_currentProduct!.id);
    } catch (e) {
      // Revert on error
      _isWishlisted = !_isWishlisted;
      notifyListeners();
    }
  }

  Future<void> addToCart() async {
    if (_currentProduct == null) return;
    if (variants.isEmpty) return;

    _isAddingToCart = true;
    notifyListeners();

    try {
      await _service.addToCart(
        _currentProduct!.id,
        _quantity,
        variants[_selectedVariantIndex].id,
      );
      // Reset quantity after successful add
      _quantity = 1;
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    } finally {
      _isAddingToCart = false;
      notifyListeners();
    }
  }
}
