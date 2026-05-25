import 'package:cloud_firestore/cloud_firestore.dart';

class StoreUpdateModel {
  final String updateId;
  final String storeId;
  final String storeName;
  final String storeLogo;
  final String storeBanner;
  final String type; // new_launch, restock, offer, community_update
  final String title;
  final String description;
  final String imageUrl;
  final String? productId;
  final String? productName;
  final double price;
  final double discountPrice;
  final String ctaText;
  final String badgeText;
  final bool isActive;
  final bool createdBySeeder;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoreUpdateModel({
    required this.updateId,
    required this.storeId,
    required this.storeName,
    required this.storeLogo,
    required this.storeBanner,
    required this.type,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.productId,
    this.productName,
    required this.price,
    required this.discountPrice,
    required this.ctaText,
    required this.badgeText,
    required this.isActive,
    required this.createdBySeeder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreUpdateModel.fromMap(Map<String, dynamic> map, String id) {
    return StoreUpdateModel(
      updateId: id,
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      storeLogo: map['storeLogo'] ?? '',
      storeBanner: map['storeBanner'] ?? '',
      type: map['type'] ?? 'community_update',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      productId: map['productId'],
      productName: map['productName'],
      price: (map['price'] ?? 0).toDouble(),
      discountPrice: (map['discountPrice'] ?? 0).toDouble(),
      ctaText: map['ctaText'] ?? 'View',
      badgeText: map['badgeText'] ?? '',
      isActive: map['isActive'] ?? true,
      createdBySeeder: map['createdBySeeder'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'updateId': updateId,
      'storeId': storeId,
      'storeName': storeName,
      'storeLogo': storeLogo,
      'storeBanner': storeBanner,
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      if (productId != null) 'productId': productId,
      if (productName != null) 'productName': productName,
      'price': price,
      'discountPrice': discountPrice,
      'ctaText': ctaText,
      'badgeText': badgeText,
      'isActive': isActive,
      'createdBySeeder': createdBySeeder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
