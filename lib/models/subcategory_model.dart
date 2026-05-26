class SubCategoryModel {
  final String subCategoryId;
  final String categoryId;
  final String name;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;
  final bool createdBySeeder;

  String get id => subCategoryId;

  SubCategoryModel({
    required this.subCategoryId,
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdBySeeder = false,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return SubCategoryModel(
      subCategoryId: json['subCategoryId'] ?? docId ?? '',
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? json['order'] ?? 0,
      createdBySeeder: json['createdBySeeder'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subCategoryId': subCategoryId,
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdBySeeder': createdBySeeder,
    };
  }
}
