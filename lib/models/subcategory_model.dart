class SubCategoryModel {
  final String subCategoryId;
  final String categoryId;
  final String name;
  final String slug;
  final String description;
  final Map<String, dynamic>? image;
  final int productsCount; // legacy
  final int storesCount; // legacy
  final int tagsCount; // legacy
  final bool isPopular;
  final String status;
  final int displayIndex;
  final List<String>? aliases;
  final List<String>? searchKeywords;
  final bool createdBySeeder;
  final Map<String, dynamic>? analytics;
  final Map<String, dynamic>? metadata;

  // Backwards compatibility getters
  String get id => subCategoryId;
  String get imageUrl => image?['url'] ?? '';
  bool get isActive => status == 'active';
  int get sortOrder => displayIndex;

  SubCategoryModel({
    required this.subCategoryId,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description = '',
    this.image,
    this.productsCount = 0,
    this.storesCount = 0,
    this.tagsCount = 0,
    this.isPopular = false,
    required this.status,
    required this.displayIndex,
    this.aliases,
    this.searchKeywords,
    this.createdBySeeder = false,
    this.analytics,
    this.metadata,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return SubCategoryModel(
      subCategoryId: json['subCategoryId'] ?? docId ?? '',
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      image: (json['image'] is Map) ? Map<String, dynamic>.from(json['image'] as Map) : null,
      productsCount: (json['productsCount'] as num?)?.toInt() ?? 0,
      storesCount: (json['storesCount'] as num?)?.toInt() ?? 0,
      tagsCount: (json['tagsCount'] as num?)?.toInt() ?? 0,
      isPopular: json['isPopular'] == true,
      status: json['status']?.toString() ?? (json['isActive'] == false ? 'hidden' : 'active'),
      displayIndex: (json['displayIndex'] as num?)?.toInt() ?? (json['sortOrder'] as num?)?.toInt() ?? (json['order'] as num?)?.toInt() ?? 0,
      aliases: json['aliases'] is List ? List<String>.from(json['aliases']) : [],
      searchKeywords: json['searchKeywords'] is List ? List<String>.from(json['searchKeywords']) : [],
      createdBySeeder: json['createdBySeeder'] == true,
      analytics: (json['analytics'] is Map) ? Map<String, dynamic>.from(json['analytics'] as Map) : null,
      metadata: (json['metadata'] is Map) ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subCategoryId': subCategoryId,
      'categoryId': categoryId,
      'name': name,
      'slug': slug,
      'description': description,
      'image': image,
      'productsCount': productsCount,
      'storesCount': storesCount,
      'tagsCount': tagsCount,
      'isPopular': isPopular,
      'status': status,
      'displayIndex': displayIndex,
      'aliases': aliases,
      'searchKeywords': searchKeywords,
      'createdBySeeder': createdBySeeder,
      'analytics': analytics,
      'metadata': metadata,
    };
  }
}
