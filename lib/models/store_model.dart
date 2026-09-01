import 'package:cloud_firestore/cloud_firestore.dart';
import 'delivery_area_model.dart';

class StoreModel {
  final String id;
  final String storeId;
  final String ownerId;
  final String name; // maps to storeName
  final String storeSlug;
  final String description;
  final String logoUrl; // maps to logo
  final String bannerUrl; // maps to banner
  final String instagramLink;
  final String youtubeLink;
  final String facebookLink;
  final List<String> categories;
  final int followers;
  final int likesCount;
  final int productsCount;
  final double rating;
  final int reviewsCount;
  final int totalOrders;
  final bool isVerified; // maps to verified
  final bool isFeatured;
  final bool isActive;
  final String status; // 'Active', 'Pending', 'Suspended'
  final bool canSellPanIndia;

  bool get isSuspended =>
      status.toLowerCase() == 'suspended' ||
      (!isActive && status.toLowerCase() == 'suspended');

  final String dispatchTime;

  // Tax Info
  final String taxRegistrationType; // 'GSTIN' or 'EnrolmentNumber'
  final String taxNumber;
  final String fssaiNumber;

  // Location
  final String businessAddress;
  final String village;
  final String city;
  final String district;
  final String state;
  final String country;
  final String pincode;

  // Shipping & Delivery
  final Map<String, dynamic> shippingConfig;
  final List<DeliveryAreaModel> deliveryAreas;

  // Dates
  final String createdAt;

  StoreModel({
    required this.id,
    required this.storeId,
    required this.ownerId,
    required this.name,
    required this.storeSlug,
    required this.description,
    required this.logoUrl,
    required this.bannerUrl,
    required this.instagramLink,
    required this.youtubeLink,
    required this.facebookLink,
    required this.categories,
    required this.followers,
    required this.likesCount,
    required this.productsCount,
    required this.rating,
    required this.reviewsCount,
    required this.totalOrders,
    required this.isVerified,
    required this.isFeatured,
    required this.isActive,
    this.status = 'Active',
    required this.canSellPanIndia,
    required this.dispatchTime,
    this.taxRegistrationType = '',
    this.taxNumber = '',
    this.fssaiNumber = '',
    this.businessAddress = '',
    this.village = '',
    this.city = '',
    this.district = '',
    this.state = '',
    this.country = '',
    this.pincode = '',
    this.shippingConfig = const {},
    this.deliveryAreas = const [],
    this.createdAt = '',
  });

  factory StoreModel.fromJson(Map<String, dynamic> json, String documentId) {
    return StoreModel(
      id: documentId,
      storeId: json['storeId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      name: json['storeName'] ?? json['name'] ?? '',
      storeSlug: json['storeSlug'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logo'] ?? json['logoUrl'] ?? '',
      bannerUrl: json['banner'] ?? json['bannerUrl'] ?? '',
      instagramLink: json['instagramLink'] ?? '',
      youtubeLink: json['youtubeLink'] ?? '',
      facebookLink: json['facebookLink'] ?? '',
      categories: List<String>.from(json['categories'] ?? json['tags'] ?? []),
      followers: json['followers'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      productsCount: json['productsCount'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['totalReviews'] ?? json['reviewsCount'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      isVerified: json['verified'] ?? json['isVerified'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      isActive: json['isActive'] ?? true,
      status: json['status'] ?? 'Active',
      canSellPanIndia: json['canSellPanIndia'] ?? false,
      dispatchTime: json['dispatchTime'] ?? '1-2 Days',
      taxRegistrationType: json['taxRegistrationType'] ?? '',
      taxNumber: json['taxNumber'] ?? '',
      fssaiNumber: json['fssaiNumber'] ?? '',
      businessAddress: json['businessAddress'] ?? '',
      village: json['village'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? '',
      shippingConfig: json['shippingConfig'] ?? {},
      deliveryAreas:
          json['deliveryAreas'] != null &&
              (json['deliveryAreas'] as List).isNotEmpty
          ? (json['deliveryAreas'] as List)
                .map((e) => DeliveryAreaModel.fromJson(e))
                .toList()
          : DeliveryAreaModel.createDefaultAreas(
              json['state'] ?? '',
              json['canSellPanIndia'] ?? false,
            ),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
                ? (json['createdAt'] as Timestamp).toDate().toIso8601String()
                : json['createdAt'].toString())
          : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'ownerId': ownerId,
      'storeName': name,
      'storeSlug': storeSlug,
      'description': description,
      'logo': logoUrl,
      'banner': bannerUrl,
      'instagramLink': instagramLink,
      'youtubeLink': youtubeLink,
      'facebookLink': facebookLink,
      'categories': categories,
      'followers': followers,
      'likesCount': likesCount,
      'productsCount': productsCount,
      'rating': rating,
      'totalReviews': reviewsCount,
      'totalOrders': totalOrders,
      'verified': isVerified,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'canSellPanIndia': canSellPanIndia,
      'dispatchTime': dispatchTime,
      'taxRegistrationType': taxRegistrationType,
      'taxNumber': taxNumber,
      'fssaiNumber': fssaiNumber,
      'businessAddress': businessAddress,
      'village': village,
      'city': city,
      'district': district,
      'state': state,
      'country': country,
      'pincode': pincode,
      'shippingConfig': shippingConfig,
      'deliveryAreas': deliveryAreas.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
    };
  }
}
