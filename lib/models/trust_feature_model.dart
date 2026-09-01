class TrustFeatureModel {
  final String id;
  final String title;
  final String subtitle;
  final String iconName;

  TrustFeatureModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconName,
  });

  factory TrustFeatureModel.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return TrustFeatureModel(
      id: documentId,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      iconName: json['iconName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'subtitle': subtitle, 'iconName': iconName};
  }
}
