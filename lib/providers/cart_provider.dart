import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class CartProvider with ChangeNotifier {
  static const String _cartPrefsKey = 'freshga_cart_items';
  
  Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => {..._items};

  int get itemCount => _items.length;

  bool get isEmpty => _items.isEmpty;

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartJsonString = prefs.getString(_cartPrefsKey);
      
      if (cartJsonString != null) {
        final Map<String, dynamic> cartMap = json.decode(cartJsonString);
        _items = cartMap.map(
          (key, value) => MapEntry(key, CartItemModel.fromJson(value)),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cartJsonString = json.encode(
        _items.map((key, value) => MapEntry(key, value.toJson())),
      );
      await prefs.setString(_cartPrefsKey, cartJsonString);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  String _generateCartItemId(String productId, String variantId) {
    return '${productId}_$variantId';
  }

  void addToCart({
    required ProductModel product,
    required ProductVariantModel variant,
    int quantity = 1,
  }) {
    final cartItemId = _generateCartItemId(product.id, variant.id);

    if (_items.containsKey(cartItemId)) {
      _items.update(
        cartItemId,
        (existingCartItem) => existingCartItem.copyWith(
          quantity: existingCartItem.quantity + quantity,
        ),
      );
    } else {
      _items.putIfAbsent(
        cartItemId,
        () => CartItemModel(
          cartItemId: cartItemId,
          productId: product.id,
          variantId: variant.id,
          storeId: product.storeId,
          storeName: product.storeName,
          productName: product.name,
          imageUrl: product.imageUrl,
          variantLabel: variant.label,
          price: variant.discountPrice > 0 ? variant.discountPrice : variant.price,
          originalPrice: variant.price,
          quantity: quantity,
          addedAt: DateTime.now(),
          isAvailable: variant.inStock,
          dispatchTime: product.dispatchTime,
        ),
      );
    }
    _saveCart();
    notifyListeners();
  }

  void removeFromCart(String cartItemId) {
    _items.remove(cartItemId);
    _saveCart();
    notifyListeners();
  }

  void incrementQuantity(String cartItemId) {
    if (_items.containsKey(cartItemId)) {
      _items.update(
        cartItemId,
        (existingCartItem) => existingCartItem.copyWith(
          quantity: existingCartItem.quantity + 1,
        ),
      );
      _saveCart();
      notifyListeners();
    }
  }

  void decrementQuantity(String cartItemId) {
    if (!_items.containsKey(cartItemId)) return;

    if (_items[cartItemId]!.quantity > 1) {
      _items.update(
        cartItemId,
        (existingCartItem) => existingCartItem.copyWith(
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(cartItemId);
    }
    _saveCart();
    notifyListeners();
  }

  void clearStoreCart(String storeId) {
    _items.removeWhere((key, item) => item.storeId == storeId);
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  Map<String, List<CartItemModel>> getStoreGroupedItems() {
    final Map<String, List<CartItemModel>> groupedItems = {};
    for (var item in _items.values) {
      if (!groupedItems.containsKey(item.storeId)) {
        groupedItems[item.storeId] = [];
      }
      groupedItems[item.storeId]!.add(item);
    }
    return groupedItems;
  }

  int get totalItems {
    int total = 0;
    for (var item in _items.values) {
      total += item.quantity;
    }
    return total;
  }

  int get totalStores {
    return _items.values.map((e) => e.storeId).toSet().length;
  }

  double get totalPrice {
    double total = 0.0;
    for (var item in _items.values) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  double getStoreTotal(String storeId) {
    double total = 0.0;
    for (var item in _items.values.where((e) => e.storeId == storeId)) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  int getStoreItemCount(String storeId) {
    int total = 0;
    for (var item in _items.values.where((e) => e.storeId == storeId)) {
      total += item.quantity;
    }
    return total;
  }

  bool isProductInCart(String productId, String variantId) {
    return _items.containsKey(_generateCartItemId(productId, variantId));
  }

  CartItemModel? getCartItem(String productId, String variantId) {
    return _items[_generateCartItemId(productId, variantId)];
  }

  Future<List<String>> validateCartForCheckout(String storeId) async {
    final storeItems = _items.values.where((item) => item.storeId == storeId).toList();
    if (storeItems.isEmpty) return [];

    List<String> messages = [];
    final productService = ProductService();

    for (var item in storeItems) {
      try {
        final liveProduct = await productService.getProduct(item.productId);
        if (liveProduct == null || !liveProduct.status.startsWith('Live')) {
           _items.update(item.cartItemId, (i) => i.copyWith(isAvailable: false));
           messages.add('${item.productName} is no longer available.');
           continue;
        }

        final variant = liveProduct.variants.firstWhere(
           (v) => v.id == item.variantId,
           orElse: () => ProductVariantModel(id: '', label: '', price: 0, discountPrice: 0, stock: 0, inStock: false, isArchived: true)
        );

        if (variant.id.isEmpty || variant.isArchived) {
           _items.update(item.cartItemId, (i) => i.copyWith(isAvailable: false));
           messages.add('${item.productName} (${item.variantLabel}) is no longer available.');
           continue;
        }

        double livePrice = variant.discountPrice > 0 ? variant.discountPrice : variant.price;
        if (livePrice != item.price) {
           _items.update(item.cartItemId, (i) => i.copyWith(price: livePrice));
           messages.add('${item.productName} price changed from ₹${item.price.toInt()} to ₹${livePrice.toInt()}.');
        }

        if (!variant.inStock || variant.stock < item.quantity) {
           if (variant.stock > 0) {
              _items.update(item.cartItemId, (i) => i.copyWith(quantity: variant.stock));
              messages.add('Only ${variant.stock} left for ${item.productName}. Quantity updated.');
           } else {
              _items.update(item.cartItemId, (i) => i.copyWith(isAvailable: false));
              messages.add('${item.productName} is out of stock.');
           }
        }
      } catch (e) {
        debugPrint('Validation failed for ${item.productId}: $e');
      }
    }

    if (messages.isNotEmpty) {
      _saveCart();
      notifyListeners();
    }
    
    return messages;
  }
}
