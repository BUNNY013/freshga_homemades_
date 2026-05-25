import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _service = ProductService();
  
  List<ProductModel> _trendingProducts = [];
  bool _isLoadingTrending = false;

  List<ProductModel> get trendingProducts => _trendingProducts;
  bool get isLoadingTrending => _isLoadingTrending;

  // New states for product details
  ProductModel? _currentProduct;
  bool _isLoadingProduct = false;
  
  List<ProductModel> _similarProducts = [];
  bool _isLoadingSimilar = false;

  List<ProductModel> _suggestedProducts = [];
  bool _isLoadingSuggested = false;

  // Interaction states
  int _selectedVariantIndex = 0;
  int _quantity = 1;
  bool _isWishlisted = false;
  bool _isAddingToCart = false;

  ProductModel? get currentProduct => _currentProduct;
  bool get isLoadingProduct => _isLoadingProduct;
  List<ProductModel> get similarProducts => _similarProducts;
  bool get isLoadingSimilar => _isLoadingSimilar;
  List<ProductModel> get suggestedProducts => _suggestedProducts;
  bool get isLoadingSuggested => _isLoadingSuggested;

  int get selectedVariantIndex => _selectedVariantIndex;
  int get quantity => _quantity;
  bool get isWishlisted => _isWishlisted;
  bool get isAddingToCart => _isAddingToCart;
  
  List<ProductVariantModel> get variants => _currentProduct?.variants ?? [];

  double get currentVariantPrice {
    if (variants.isEmpty) return _currentProduct?.price ?? 0.0;
    if (_selectedVariantIndex >= variants.length) return _currentProduct?.price ?? 0.0;
    final variant = variants[_selectedVariantIndex];
    return variant.discountPrice > 0 ? variant.discountPrice : variant.price;
  }

  double get currentVariantOriginalPrice {
    if (variants.isEmpty) return _currentProduct?.originalPrice ?? 0.0;
    if (_selectedVariantIndex >= variants.length) return _currentProduct?.originalPrice ?? 0.0;
    return variants[_selectedVariantIndex].price;
  }

  Future<void> loadTrendingProducts() async {
    _isLoadingTrending = true;
    notifyListeners();
    try {
      _trendingProducts = await _service.getTrendingProducts();
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
    _selectedVariantIndex = 0;
    _quantity = 1;
    notifyListeners();

    try {
      _currentProduct = await _service.getProduct(productId);
      if (_currentProduct != null) {
        // Fetch recommendations in parallel
        _fetchRecommendations(_currentProduct!);
      }
    } catch (e) {
      debugPrint('Error loading product: $e');
    } finally {
      _isLoadingProduct = false;
      notifyListeners();
    }
  }

  Future<void> _fetchRecommendations(ProductModel product) async {
    _isLoadingSimilar = true;
    _isLoadingSuggested = true;
    notifyListeners();

    try {
      final similarFuture = _service.getSimilarProducts(product);
      final suggestedFuture = _service.getSuggestedProducts(product);

      final results = await Future.wait([similarFuture, suggestedFuture]);
      
      _similarProducts = results[0];
      _suggestedProducts = results[1];
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    } finally {
      _isLoadingSimilar = false;
      _isLoadingSuggested = false;
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
        variants[_selectedVariantIndex].id
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
