class StoreModel {
  final String id;
  final String name;
  final String logoUrl;
  final String bannerUrl;
  final double rating;
  final int reviewsCount;
  final int totalOrders;
  final int followers;
  final String description;
  final String dispatchTime;
  final bool isVerified;
  final bool isFeatured;
  final List<String> tags;

  StoreModel({
    required this.id, required this.name, required this.logoUrl, required this.bannerUrl,
    required this.rating, required this.reviewsCount, required this.totalOrders,
    required this.followers, required this.description, required this.dispatchTime,
    required this.isVerified, required this.isFeatured, required this.tags
  });

  factory StoreModel.fromJson(Map<String, dynamic> json, String documentId) {
    return StoreModel(
      id: documentId,
      name: json['storeName'] ?? json['name'] ?? '',
      logoUrl: json['logo'] ?? json['logoUrl'] ?? '',
      bannerUrl: json['banner'] ?? json['bannerUrl'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['totalReviews'] ?? json['reviewsCount'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      followers: json['followers'] ?? 0,
      description: json['description'] ?? '',
      dispatchTime: json['dispatchTime'] ?? '30-40 mins',
      isVerified: json['verified'] ?? json['isVerified'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      tags: List<String>.from(json['categories'] ?? json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeName': name,
      'logo': logoUrl,
      'banner': bannerUrl,
      'rating': rating,
      'totalReviews': reviewsCount,
      'totalOrders': totalOrders,
      'followers': followers,
      'description': description,
      'dispatchTime': dispatchTime,
      'verified': isVerified,
      'isFeatured': isFeatured,
      'categories': tags,
    };
  }
}
