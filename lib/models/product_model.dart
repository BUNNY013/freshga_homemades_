class ProductModel {
  final String id;
  final String storeId;
  final String storeName;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final bool isTrending;
  final double rating;
  final int reviewsCount;
  final String weight; // e.g., "250g"

  ProductModel({
    required this.id, required this.storeId, required this.storeName, required this.name, required this.description,
    required this.price, required this.originalPrice, required this.imageUrl, 
    required this.isTrending, required this.rating, required this.reviewsCount, required this.weight,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json, String documentId) {
    // Safely extract from Vendor App schema
    List<dynamic> images = json['images'] ?? [];
    String firstImage = images.isNotEmpty ? images.first.toString() : '';

    List<dynamic> variants = json['variants'] ?? [];
    double currentPrice = 0.0;
    String variantWeight = "";
    if (variants.isNotEmpty) {
      var firstVariant = variants.first;
      if (firstVariant is Map) {
        currentPrice = (firstVariant['price'] ?? 0.0).toDouble();
        // Try to construct weight/unit if available
        if (firstVariant.containsKey('value') && firstVariant.containsKey('unit')) {
          variantWeight = "${firstVariant['value']}${firstVariant['unit']}";
        }
      }
    }

    // Fallbacks just in case it's the old schema
    if (currentPrice == 0.0) currentPrice = (json['price'] ?? 0.0).toDouble();
    if (firstImage.isEmpty) firstImage = json['imageUrl'] ?? '';

    return ProductModel(
      id: documentId,
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: currentPrice,
      originalPrice: (json['originalPrice'] ?? 0.0).toDouble(),
      imageUrl: firstImage,
      isTrending: json['isTrending'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['totalReviews'] ?? json['reviewsCount'] ?? 0,
      weight: variantWeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'isTrending': isTrending,
      'rating': rating,
      'totalReviews': reviewsCount,
    };
  }
}
