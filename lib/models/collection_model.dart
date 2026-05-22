class CollectionModel {
  final String id;
  final String title;
  final String subtitle;
  final String bannerUrl;
  final List<String> productIds;

  CollectionModel({
    required this.id, required this.title, required this.subtitle, 
    required this.bannerUrl, required this.productIds
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json, String documentId) {
    return CollectionModel(
      id: documentId,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      bannerUrl: json['bannerUrl'] ?? '',
      productIds: List<String>.from(json['productIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'bannerUrl': bannerUrl,
      'productIds': productIds,
    };
  }
}
