class CategoryModel {
  final String categoryId;
  final String name;
  final String slug;
  final String imageUrl;
  final Map<String, dynamic>? image;
  final Map<String, dynamic>? banner;
  final String? themeColor;
  final int itemCount;
  final bool isActive;
  final bool isFeatured;
  final int sortOrder;
  final String description;
  final List<String>? searchKeywords;
  final bool createdBySeeder;

  // Backwards compatibility getters
  String get id => categoryId;
  int get order => sortOrder;

  CategoryModel({
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.imageUrl,
    this.image,
    this.banner,
    this.themeColor,
    required this.itemCount,
    required this.isActive,
    this.isFeatured = false,
    required this.sortOrder,
    this.description = '',
    this.searchKeywords,
    this.createdBySeeder = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return CategoryModel(
      categoryId: json['categoryId'] ?? docId ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      image: json['image'],
      banner: json['banner'],
      themeColor: json['themeColor'],
      itemCount: json['itemCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      sortOrder: json['sortOrder'] ?? json['order'] ?? 0,
      description: json['description'] ?? json['tagline'] ?? '',
      searchKeywords: List<String>.from(json['searchKeywords'] ?? []),
      createdBySeeder: json['createdBySeeder'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'slug': slug,
      'imageUrl': imageUrl,
      'image': image,
      'banner': banner,
      'themeColor': themeColor,
      'itemCount': itemCount,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'sortOrder': sortOrder,
      'description': description,
      'searchKeywords': searchKeywords,
      'createdBySeeder': createdBySeeder,
    };
  }
}
