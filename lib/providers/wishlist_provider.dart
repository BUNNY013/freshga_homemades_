import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../services/wishlist_service.dart';

class WishlistProvider with ChangeNotifier {
  final WishlistService _service = WishlistService();

  List<ProductModel> _likedProducts = [];
  Set<String> _likedProductIds = {};
  bool _isLoading = true;

  StreamSubscription<List<ProductModel>>? _productsSub;
  StreamSubscription<Set<String>>? _idsSub;
  StreamSubscription<User?>? _authSub;

  List<ProductModel> get likedProducts => _likedProducts;
  Set<String> get likedProductIds => _likedProductIds;
  bool get isLoading => _isLoading;

  WishlistProvider() {
    _init();
  }

  void _init() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _subscribeToWishlist();
    });
  }

  void _subscribeToWishlist() {
    _productsSub?.cancel();
    _idsSub?.cancel();

    if (FirebaseAuth.instance.currentUser == null) {
      _likedProducts = [];
      _likedProductIds = {};
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // 1. Immediate one-time fetch to prevent infinite loading spinners on 0 items
    _service.getLikedProductsOnce().then((products) {
      if (_isLoading) {
        _likedProducts = products;
        _likedProductIds = products.map((p) => p.id).toSet();
        _isLoading = false;
        notifyListeners();
      }
    }).catchError((e) {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    });

    // 2. Real-time subscriptions
    _idsSub = _service.getLikedProductIdsStream().listen((ids) {
      _likedProductIds = ids;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      notifyListeners();
    });

    _productsSub = _service.getLikedProductsStream().listen((products) {
      _likedProducts = products;
      _likedProductIds = products.map((p) => p.id).toSet();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      notifyListeners();
    });
  }

  bool isLiked(String productId) {
    return _likedProductIds.contains(productId);
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final products = await _service.getLikedProductsOnce();
      _likedProducts = products;
      _likedProductIds = products.map((p) => p.id).toSet();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(ProductModel product) async {
    final currentlyLiked = isLiked(product.id);
    // Optimistic UI update
    if (currentlyLiked) {
      _likedProductIds.remove(product.id);
      _likedProducts.removeWhere((p) => p.id == product.id);
    } else {
      _likedProductIds.add(product.id);
      if (!_likedProducts.any((p) => p.id == product.id)) {
        _likedProducts.insert(0, product);
      }
    }
    notifyListeners();

    try {
      await _service.toggleLike(product, currentlyLiked);
    } catch (e) {
      // Revert if failed
      if (currentlyLiked) {
        _likedProductIds.add(product.id);
        _likedProducts.insert(0, product);
      } else {
        _likedProductIds.remove(product.id);
        _likedProducts.removeWhere((p) => p.id == product.id);
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeLike(String productId) async {
    final removedProduct = _likedProducts.cast<ProductModel?>().firstWhere((p) => p?.id == productId, orElse: () => null);
    _likedProductIds.remove(productId);
    _likedProducts.removeWhere((p) => p.id == productId);
    notifyListeners();

    try {
      await _service.unlikeProduct(productId);
    } catch (e) {
      if (removedProduct != null) {
        _likedProductIds.add(productId);
        _likedProducts.add(removedProduct);
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _idsSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
