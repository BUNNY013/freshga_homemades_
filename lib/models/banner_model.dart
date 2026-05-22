class BannerModel {
  final String id;
  final String imageUrl;
  final String linkUrl;
  final bool isActive;
  final int order;
  final String? badgeText;
  final String? title;
  final String? subtitle;
  final String? buttonText;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.linkUrl,
    required this.isActive,
    required this.order,
    this.badgeText,
    this.title,
    this.subtitle,
    this.buttonText,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json, String documentId) {
    return BannerModel(
      id: documentId,
      imageUrl: json['imageUrl'] ?? '',
      linkUrl: json['linkUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      badgeText: json['badgeText'],
      title: json['title'],
      subtitle: json['subtitle'],
      buttonText: json['buttonText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'isActive': isActive,
      'order': order,
      if (badgeText != null) 'badgeText': badgeText,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (buttonText != null) 'buttonText': buttonText,
    };
  }
}
