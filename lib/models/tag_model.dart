import 'package:cloud_firestore/cloud_firestore.dart';

class TagModel {
  final String tagId;
  final String name;
  final String slug;
  final String icon;

  final List<String> categoryIds;
  final List<String> subCategoryIds;

  final int priority;

  final bool isTrending;
  final bool isFilterable;
  final bool isSearchable;
  final bool isActive;

  final List<String> searchKeywords;

  final bool createdBySeeder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get id => tagId;

  TagModel({
    required this.tagId,
    required this.name,
    required this.slug,
    this.icon = '',
    this.categoryIds = const [],
    this.subCategoryIds = const [],
    this.priority = 0,
    this.isTrending = false,
    this.isFilterable = true,
    this.isSearchable = true,
    this.isActive = true,
    this.searchKeywords = const [],
    this.createdBySeeder = false,
    this.createdAt,
    this.updatedAt,
  });

  factory TagModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return TagModel(
      tagId: json['tagId'] ?? docId ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'] ?? '',
      categoryIds: List<String>.from(json['categoryIds'] ?? []),
      subCategoryIds: List<String>.from(json['subCategoryIds'] ?? []),
      priority: json['priority'] ?? 0,
      isTrending: json['isTrending'] ?? false,
      isFilterable: json['isFilterable'] ?? true,
      isSearchable: json['isSearchable'] ?? true,
      isActive: json['isActive'] ?? true,
      searchKeywords: List<String>.from(json['searchKeywords'] ?? []),
      createdBySeeder: json['createdBySeeder'] ?? false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tagId': tagId,
      'name': name,
      'slug': slug,
      'icon': icon,
      'categoryIds': categoryIds,
      'subCategoryIds': subCategoryIds,
      'priority': priority,
      'isTrending': isTrending,
      'isFilterable': isFilterable,
      'isSearchable': isSearchable,
      'isActive': isActive,
      'searchKeywords': searchKeywords,
      'createdBySeeder': createdBySeeder,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
