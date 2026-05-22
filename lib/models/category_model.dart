class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final bool isActive;
  final int order;
  final int itemCount;

  CategoryModel({required this.id, required this.name, required this.imageUrl, required this.isActive, required this.order, this.itemCount = 0});

  factory CategoryModel.fromJson(Map<String, dynamic> json, String documentId) {
    return CategoryModel(
      id: documentId,
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      itemCount: json['itemCount'] ?? (10 + (documentId.hashCode % 100)), // Fallback mock value for UI if not present
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'order': order,
    };
  }
}
