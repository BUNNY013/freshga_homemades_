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
  final String dispatchTime;
  
  // Location
  final String city;
  final String state;
  final String country;
  final String pincode;

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
    required this.dispatchTime,
    this.city = '',
    this.state = '',
    this.country = '',
    this.pincode = '',
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
      dispatchTime: json['dispatchTime'] ?? '24 hours',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? '',
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
      'dispatchTime': dispatchTime,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
    };
  }
}
