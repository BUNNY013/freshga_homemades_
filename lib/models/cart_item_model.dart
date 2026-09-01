class CartItemModel {
  final String cartItemId;
  final String productId;
  final String variantId;
  final String storeId;
  final String storeName;
  final String productName;
  final String imageUrl;
  final String variantLabel;
  final double price;
  final double originalPrice;
  final int quantity;
  final DateTime addedAt;
  final bool isAvailable;
  final String dispatchTime;
  final bool manageStock;
  final int stock;

  CartItemModel({
    required this.cartItemId,
    required this.productId,
    required this.variantId,
    required this.storeId,
    required this.storeName,
    required this.productName,
    required this.imageUrl,
    required this.variantLabel,
    required this.price,
    required this.originalPrice,
    required this.quantity,
    required this.addedAt,
    required this.isAvailable,
    required this.dispatchTime,
    this.manageStock = false,
    this.stock = 0,
  });

  CartItemModel copyWith({
    String? cartItemId,
    String? productId,
    String? variantId,
    String? storeId,
    String? storeName,
    String? productName,
    String? imageUrl,
    String? variantLabel,
    double? price,
    double? originalPrice,
    int? quantity,
    DateTime? addedAt,
    bool? isAvailable,
    String? dispatchTime,
    bool? manageStock,
    int? stock,
  }) {
    return CartItemModel(
      cartItemId: cartItemId ?? this.cartItemId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      variantLabel: variantLabel ?? this.variantLabel,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      dispatchTime: dispatchTime ?? this.dispatchTime,
      manageStock: manageStock ?? this.manageStock,
      stock: stock ?? this.stock,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      cartItemId: json['cartItemId'] ?? '',
      productId: json['productId'] ?? '',
      variantId: json['variantId'] ?? '',
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      productName: json['productName'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      variantLabel: json['variantLabel'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt']) ?? DateTime.now()
          : DateTime.now(),
      isAvailable: json['isAvailable'] ?? true,
      dispatchTime: json['dispatchTime'] ?? '2 Days',
      manageStock: json['manageStock'] ?? false,
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartItemId': cartItemId,
      'productId': productId,
      'variantId': variantId,
      'storeId': storeId,
      'storeName': storeName,
      'productName': productName,
      'imageUrl': imageUrl,
      'variantLabel': variantLabel,
      'price': price,
      'originalPrice': originalPrice,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'isAvailable': isAvailable,
      'dispatchTime': dispatchTime,
      'manageStock': manageStock,
      'stock': stock,
    };
  }
}
