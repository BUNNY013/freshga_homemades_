import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tag_model.dart';
import 'utils/slug_generator.dart';
import 'utils/keyword_generator.dart';
import 'utils/tag_mapper.dart';
import 'data/categories_data.dart';

class TagsSeeder {
  static Future<void> seedTags() async {
    print('🌱 Seeding tags collection and mapping subcategories...');

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final tagsCol = firestore.collection('tags');

    // 1. We will read the categories data to figure out which tag applies to which subcategory
    final lines = categoriesRawData.split('\n');
    final categoryRegex = RegExp(
      r'(?:[\u2700-\u27BF]|[\uE000-\uF8FF]|\uD83C[\uDC00-\uDFFF]|\uD83D[\uDC00-\uDFFF]|[\u2011-\u26FF]|\uD83E[\uDD10-\uDDFF])?\s*\d+\.\s+(.*)',
    );
    final subCategoryRegex = RegExp(r'^\s*•\s+(.*)');

    String currentCategoryName = '';
    Map<String, List<String>> tagToSubIds = {};

    for (var line in lines) {
      final catMatch = categoryRegex.firstMatch(line.trim());
      if (catMatch != null) {
        currentCategoryName = catMatch.group(1)!.trim();
        continue;
      }

      final subMatch = subCategoryRegex.firstMatch(line);
      if (subMatch != null && currentCategoryName.isNotEmpty) {
        final rawName = subMatch.group(1)!.trim();
        final slug = SlugGenerator.generate('$currentCategoryName $rawName');

        final mappedTags = TagMapper.autoMapTagsForCategory(
          currentCategoryName,
        );

        for (var tag in mappedTags) {
          final tagSlug = SlugGenerator.generate(tag);
          tagToSubIds.putIfAbsent(tagSlug, () => []).add(slug);
        }
      }
    }

    int count = 0;
    for (var tagData in TagMapper.predefinedTags) {
      final name = tagData['name'] as String;
      final icon = tagData['icon'] as String;
      final isFilterable = tagData['isFilterable'] as bool;

      final slug = SlugGenerator.generate(name);
      final docRef = tagsCol.doc(slug);

      final keywords = KeywordGenerator.generateForEntity(name: name);
      final subCategoryIds = tagToSubIds[slug] ?? [];

      final tagModel = TagModel(
        tagId: slug,
        name: name,
        slug: slug,
        icon: icon,
        isFilterable: isFilterable,
        isTrending: count < 5, // make first 5 trending
        priority: 100 - count,
        searchKeywords: keywords,
        subCategoryIds: subCategoryIds,
        createdBySeeder: true,
      );

      batch.set(docRef, tagModel.toJson(), SetOptions(merge: true));
      count++;
    }

    await batch.commit();
    print(
      '✅ Successfully seeded $count tags mapped to their exact subcategories.',
    );
  }
}
