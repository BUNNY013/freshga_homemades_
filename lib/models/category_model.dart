class CategoryModel {
  final String categoryId;
  final String name;
  final String slug;
  final String imageUrl;
  final int itemCount;
  final bool isActive;
  final int sortOrder;
  final String description;

  // Backwards compatibility getters
  String get id => categoryId;
  int get order => sortOrder;

  CategoryModel({
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.itemCount,
    required this.isActive,
    required this.sortOrder,
    this.description = '',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return CategoryModel(
      categoryId: json['categoryId'] ?? docId ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      itemCount: json['itemCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? json['order'] ?? 0,
      description: json['description'] ?? json['tagline'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'slug': slug,
      'imageUrl': imageUrl,
      'itemCount': itemCount,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'description': description,
    };
  }
}
