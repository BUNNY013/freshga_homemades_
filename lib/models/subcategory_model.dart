class SubCategoryModel {
  final String subCategoryId;
  final String categoryId;
  final String name;
  final String slug;
  final String description;
  final String imageUrl;
  final Map<String, dynamic>? image;
  final int productsCount;
  final int storesCount;
  final int tagsCount;
  final bool isPopular;
  final bool isActive;
  final int sortOrder;
  final List<String>? aliases;
  final List<String>? searchKeywords;
  final bool createdBySeeder;

  String get id => subCategoryId;

  SubCategoryModel({
    required this.subCategoryId,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description = '',
    required this.imageUrl,
    this.image,
    this.productsCount = 0,
    this.storesCount = 0,
    this.tagsCount = 0,
    this.isPopular = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.aliases,
    this.searchKeywords,
    this.createdBySeeder = false,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return SubCategoryModel(
      subCategoryId: json['subCategoryId'] ?? docId ?? '',
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      image: json['image'],
      productsCount: json['productsCount'] ?? 0,
      storesCount: json['storesCount'] ?? 0,
      tagsCount: json['tagsCount'] ?? 0,
      isPopular: json['isPopular'] ?? false,
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? json['order'] ?? 0,
      aliases: json['aliases'] != null ? List<String>.from(json['aliases']) : null,
      searchKeywords: json['searchKeywords'] != null ? List<String>.from(json['searchKeywords']) : null,
      createdBySeeder: json['createdBySeeder'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subCategoryId': subCategoryId,
      'categoryId': categoryId,
      'name': name,
      'slug': slug,
      'description': description,
      'imageUrl': imageUrl,
      'image': image,
      'productsCount': productsCount,
      'storesCount': storesCount,
      'tagsCount': tagsCount,
      'isPopular': isPopular,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'aliases': aliases,
      'searchKeywords': searchKeywords,
      'createdBySeeder': createdBySeeder,
    };
  }
}
