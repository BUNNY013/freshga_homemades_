class HomeSectionModel {
  final String id;
  final String
  type; // heroBanner, categories, featuredStores, trendingProducts, collections, trustStrip
  final String title;
  final String subtitle;
  final bool isActive;
  final int order;
  final Map<String, dynamic> config;

  HomeSectionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.order,
    required this.config,
  });

  factory HomeSectionModel.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return HomeSectionModel(
      id: documentId,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      config: json['config'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'isActive': isActive,
      'order': order,
      'config': config,
    };
  }
}
