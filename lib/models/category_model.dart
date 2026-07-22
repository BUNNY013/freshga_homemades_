class CategoryModel {
  final String categoryId;
  final String name;
  final String slug;
  final Map<String, dynamic>? image;
  final Map<String, dynamic>? banner;
  final int itemCount; // Legacy
  final String status;
  final bool isFeatured;
  final int displayIndex;
  final String description;
  final List<String>? searchKeywords;
  final bool createdBySeeder;
  final Map<String, dynamic>? analytics;
  final Map<String, dynamic>? metadata;

  // Backwards compatibility getters for smooth transition in places that haven't updated yet
  String get id => categoryId;
  String get imageUrl => image?['url'] ?? '';
  bool get isActive => status == 'active';
  int get sortOrder => displayIndex;

  CategoryModel({
    required this.categoryId,
    required this.name,
    required this.slug,
    this.image,
    this.banner,
    required this.itemCount,
    required this.status,
    this.isFeatured = false,
    required this.displayIndex,
    this.description = '',
    this.searchKeywords,
    this.createdBySeeder = false,
    this.analytics,
    this.metadata,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return CategoryModel(
      categoryId: json['categoryId'] ?? docId ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      image: (json['image'] is Map) ? Map<String, dynamic>.from(json['image'] as Map) : null,
      banner: (json['banner'] is Map) ? Map<String, dynamic>.from(json['banner'] as Map) : null,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? (json['isActive'] == false ? 'hidden' : 'active'),
      isFeatured: json['isFeatured'] == true,
      displayIndex: (json['displayIndex'] as num?)?.toInt() ?? (json['sortOrder'] as num?)?.toInt() ?? (json['order'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? json['tagline']?.toString() ?? '',
      searchKeywords: json['searchKeywords'] is List ? List<String>.from(json['searchKeywords']) : [],
      createdBySeeder: json['createdBySeeder'] == true,
      analytics: (json['analytics'] is Map) ? Map<String, dynamic>.from(json['analytics'] as Map) : null,
      metadata: (json['metadata'] is Map) ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'slug': slug,
      'image': image,
      'banner': banner,
      'itemCount': itemCount,
      'status': status,
      'isFeatured': isFeatured,
      'displayIndex': displayIndex,
      'description': description,
      'searchKeywords': searchKeywords,
      'createdBySeeder': createdBySeeder,
      'analytics': analytics,
      'metadata': metadata,
    };
  }
}
