class ProductVariantModel {
  final String id;
  final String label;
  final double price;
  final double discountPrice;
  final int stock;
  final bool inStock;

  ProductVariantModel({
    required this.id,
    required this.label,
    required this.price,
    required this.discountPrice,
    required this.stock,
    required this.inStock,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id']?.toString() ?? json['variantId']?.toString() ?? '',
      label: (json['value'] != null && json['unit'] != null) 
          ? "${json['value']}${json['unit']}" 
          : json['label']?.toString() ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      discountPrice: (json['discountPrice'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      inStock: json['inStock'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantId': id,
      'label': label,
      'price': price,
      'discountPrice': discountPrice,
      'stock': stock,
      'inStock': inStock,
    };
  }
}

class ProductModel {
  final String id;
  final String storeId;
  final String storeName;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final List<String> images;
  final bool isTrending;
  final double rating;
  final int reviewsCount;
  final String weight; // e.g., "250g"
  final String categoryId;
  final String categoryName;
  final List<String> subCategoryIds;
  final List<String> tags;
  final List<String> searchKeywords;
  final List<String> ingredients;
  final List<ProductVariantModel> variants;
  final Map<String, int> ratingCounts;
  final Map<String, int> ratingHighlights;
  final String shelfLife;
  final String dispatchTime;
  final bool isStoreVerified;

  ProductModel({
    required this.id, required this.storeId, required this.storeName, required this.name, required this.description,
    required this.price, required this.originalPrice, required this.imageUrl, required this.images,
    required this.isTrending, required this.rating, required this.reviewsCount, required this.weight,
    required this.categoryId, required this.categoryName, required this.subCategoryIds,
    required this.tags, required this.searchKeywords, required this.ingredients, required this.variants,
    required this.ratingCounts, required this.ratingHighlights, required this.shelfLife, required this.dispatchTime,
    this.isStoreVerified = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json, String documentId) {
    List<dynamic> rawImages = json['images'] ?? [];
    List<String> images = rawImages.map((e) => e.toString()).toList();
    String firstImage = images.isNotEmpty ? images.first : '';
    if (firstImage.isEmpty) {
        firstImage = json['imageUrl'] ?? '';
        if (firstImage.isNotEmpty) {
            images = [firstImage];
        }
    }

    List<ProductVariantModel> parsedVariants = (json['variants'] as List<dynamic>? ?? [])
        .map((e) => ProductVariantModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final firstVariant = parsedVariants.isNotEmpty ? parsedVariants.first : null;

    double currentPrice = firstVariant != null 
        ? (firstVariant.discountPrice > 0 ? firstVariant.discountPrice : firstVariant.price) 
        : (json['price'] ?? 0.0).toDouble();

    double originalPrice = firstVariant?.price ?? (json['originalPrice'] ?? 0.0).toDouble();
    String variantWeight = firstVariant?.label ?? "";

    return ProductModel(
      id: documentId,
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: currentPrice,
      originalPrice: originalPrice,
      imageUrl: firstImage,
      images: images,
      isTrending: json['isTrending'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['totalReviews'] ?? json['reviewsCount'] ?? 0,
      weight: variantWeight,
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      subCategoryIds: List<String>.from(json['subCategoryIds'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      searchKeywords: List<String>.from(json['searchKeywords'] ?? []),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      variants: parsedVariants,
      ratingCounts: Map<String, int>.from(json['ratingCounts'] ?? {}),
      ratingHighlights: Map<String, int>.from(json['ratingHighlights'] ?? {}),
      shelfLife: json['shelfLife'] ?? '3 Months',
      dispatchTime: json['dispatchTime'] ?? '2 Days',
      isStoreVerified: json['isStoreVerified'] ?? false,
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
      'images': images,
      'isTrending': isTrending,
      'rating': rating,
      'totalReviews': reviewsCount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subCategoryIds': subCategoryIds,
      'tags': tags,
      'searchKeywords': searchKeywords,
      'ingredients': ingredients,
      'variants': variants.map((e) => e.toJson()).toList(),
      'ratingCounts': ratingCounts,
      'ratingHighlights': ratingHighlights,
      'shelfLife': shelfLife,
      'dispatchTime': dispatchTime,
    };
  }
}
