import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/address_model.dart';
import '../services/product_service.dart';
import '../services/store_service.dart';

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

  Future<String?> addToCart({
    required ProductModel product,
    required ProductVariantModel variant,
    int quantity = 1,
  }) async {
    // 1. Live Validation
    try {
      final liveProduct = await ProductService().getProduct(product.id);
      if (liveProduct == null || !liveProduct.status.startsWith('Live')) {
        return "This product is no longer available.";
      }
      final liveVariant = liveProduct.variants.firstWhere(
        (v) => v.id == variant.id,
        orElse: () => variant,
      );
      if (liveVariant.isOutOfStock) {
        return "This item is currently out of stock.";
      }
      variant = liveVariant; // Use latest variant data
    } catch (e) {
      debugPrint("Live check failed: $e");
    }

    final cartItemId = _generateCartItemId(product.id, variant.id);

    if (_items.containsKey(cartItemId)) {
      final currentQty = _items[cartItemId]!.quantity;
      final newQty = currentQty + quantity;

      if (variant.manageStock && newQty > variant.stock) {
        return "Only ${variant.stock} left in stock for ${variant.label.isNotEmpty ? variant.label : product.name}.";
      }

      if (newQty > 10)
        return "Maximum 10 items allowed per order."; // Hard bulk limit

      _items.update(
        cartItemId,
        (existingCartItem) => existingCartItem.copyWith(quantity: newQty),
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
          price: variant.discountPrice > 0
              ? variant.discountPrice
              : variant.price,
          originalPrice: variant.price,
          quantity: quantity,
          addedAt: DateTime.now(),
          isAvailable: !variant.isOutOfStock,
          dispatchTime: product.dispatchTime,
          manageStock: variant.manageStock,
          stock: variant.stock,
        ),
      );
    }
    _saveCart();
    notifyListeners();
    return null; // Success
  }

  void removeFromCart(String cartItemId) {
    _items.remove(cartItemId);
    _saveCart();
    notifyListeners();
  }

  String? incrementQuantity(String cartItemId) {
    if (_items.containsKey(cartItemId)) {
      final item = _items[cartItemId]!;
      if (!item.isAvailable) return "This item is currently unavailable.";
      if (item.quantity >= 10)
        return "Maximum 10 items allowed per order."; // Hard bulk limit
      if (item.manageStock && (item.quantity + 1) > item.stock) {
        return "Only ${item.stock} left in stock for ${item.variantLabel.isNotEmpty ? item.variantLabel : item.productName}.";
      }

      _items.update(
        cartItemId,
        (existingCartItem) =>
            existingCartItem.copyWith(quantity: existingCartItem.quantity + 1),
      );
      _saveCart();
      notifyListeners();
      return null;
    }
    return "Item not found in cart.";
  }

  void decrementQuantity(String cartItemId) {
    if (!_items.containsKey(cartItemId)) return;

    if (_items[cartItemId]!.quantity > 1) {
      _items.update(
        cartItemId,
        (existingCartItem) =>
            existingCartItem.copyWith(quantity: existingCartItem.quantity - 1),
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

  List<CartItemModel> getStoreItems(String storeId) {
    return _items.values.where((item) => item.storeId == storeId).toList();
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
    final storeItems = _items.values
        .where((item) => item.storeId == storeId)
        .toList();
    if (storeItems.isEmpty) return [];

    List<String> messages = [];
    final productService = ProductService();
    final storeService = StoreService();

    // Check store subscription/active status
    final isStoreActive = await storeService.isStoreActive(storeId);
    if (!isStoreActive) {
      messages.add(
        'This store is currently offline. Orders cannot be placed at this time.',
      );
      for (var item in storeItems) {
        _items.update(item.cartItemId, (i) => i.copyWith(isAvailable: false));
      }
      _saveCart();
      notifyListeners();
      return messages;
    }

    await Future.wait(
      storeItems.map((item) async {
        try {
          final liveProduct = await productService.getProduct(item.productId);
          if (liveProduct == null || !liveProduct.status.startsWith('Live')) {
            _items.update(
              item.cartItemId,
              (i) => i.copyWith(isAvailable: false),
            );
            messages.add('${item.productName} is no longer available.');
            return;
          }

          final variant = liveProduct.variants.firstWhere(
            (v) => v.id == item.variantId,
            orElse: () => ProductVariantModel(
              id: '',
              label: '',
              price: 0,
              discountPrice: 0,
              stock: 0,
              inStock: false,
              isArchived: true,
            ),
          );

          if (variant.id.isEmpty || variant.isArchived) {
            _items.update(
              item.cartItemId,
              (i) => i.copyWith(isAvailable: false),
            );
            messages.add(
              '${item.productName} (${item.variantLabel}) is no longer available.',
            );
            return;
          }

          double livePrice = variant.discountPrice > 0
              ? variant.discountPrice
              : variant.price;
          if (livePrice != item.price) {
            _items.update(item.cartItemId, (i) => i.copyWith(price: livePrice));
            messages.add(
              '${item.productName} price changed from ₹${item.price.toInt()} to ₹${livePrice.toInt()}.',
            );
          }

          if (variant.isOutOfStock) {
            if (item.isAvailable) {
              _items.update(
                item.cartItemId,
                (i) => i.copyWith(
                  isAvailable: false,
                  stock: variant.stock,
                  manageStock: variant.manageStock,
                ),
              );
              messages.add('${item.productName} is currently unavailable.');
            }
          } else {
            if (!item.isAvailable) {
              _items.update(
                item.cartItemId,
                (i) => i.copyWith(
                  isAvailable: true,
                  stock: variant.stock,
                  manageStock: variant.manageStock,
                ),
              );
              messages.add('${item.productName} is now available again.');
            }

            if (variant.manageStock && item.quantity > variant.stock) {
              _items.update(
                item.cartItemId,
                (i) => i.copyWith(
                  quantity: variant.stock,
                  stock: variant.stock,
                  manageStock: variant.manageStock,
                ),
              );
              messages.add(
                '${item.productName} (${item.variantLabel}) was reduced to ${variant.stock} as only ${variant.stock} left in stock.',
              );
            } else {
              // Just sync stock quietly
              _items.update(
                item.cartItemId,
                (i) => i.copyWith(
                  stock: variant.stock,
                  manageStock: variant.manageStock,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Validation failed for ${item.productId}: $e');
        }
      }),
    );

    if (messages.isNotEmpty) {
      _saveCart();
      notifyListeners();
    }

    return messages;
  }

  Future<String?> validateCheckoutAddress(
    String storeId,
    AddressModel deliveryAddress,
  ) async {
    try {
      final storeService = StoreService();
      final store = await storeService.getStore(storeId);
      if (store == null) return "Store not found.";

      if (!store.canSellPanIndia) {
        // Enrolled ID logic: Can only sell within their own state
        if (store.state.toLowerCase() != deliveryAddress.state.toLowerCase()) {
          return "This store is an Enrolled ID vendor and can only ship within ${store.state}. Please choose a different delivery address or remove items from this store.";
        }
      }
      return null; // Valid
    } catch (e) {
      debugPrint("Error validating address: $e");
      return "An error occurred while validating the delivery address.";
    }
  }
}
