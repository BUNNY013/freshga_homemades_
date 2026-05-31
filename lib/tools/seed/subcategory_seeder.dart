import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/subcategory_model.dart';
import 'utils/slug_generator.dart';
import 'utils/keyword_generator.dart';
import 'utils/alias_generator.dart';
import 'utils/tag_mapper.dart';
import 'data/categories_data.dart';

class SubCategorySeeder {
  static Future<void> seedSubCategories() async {
    print('📂 Seeding sub-categories from Dart constant...');
    
    final lines = categoriesRawData.split('\n');
    final firestore = FirebaseFirestore.instance;
    // Create batches
    var batch = firestore.batch();
    final subCategoriesCol = firestore.collection('sub_categories');

    final categoryRegex = RegExp(r'(?:[\u2700-\u27BF]|[\uE000-\uF8FF]|\uD83C[\uDC00-\uDFFF]|\uD83D[\uDC00-\uDFFF]|[\u2011-\u26FF]|\uD83E[\uDD10-\uDDFF])?\s*\d+\.\s+(.*)');
    final subCategoryRegex = RegExp(r'^\s*•\s+(.*)');

    String currentCategoryId = '';
    String currentCategoryName = '';
    int sortOrder = 1;
    int count = 0;

    for (var line in lines) {
      final catMatch = categoryRegex.firstMatch(line.trim());
      if (catMatch != null) {
        currentCategoryName = catMatch.group(1)!.trim();
        currentCategoryId = SlugGenerator.generate(currentCategoryName);
        sortOrder = 1; // Reset for new category
        continue;
      }

      final subMatch = subCategoryRegex.firstMatch(line);
      if (subMatch != null && currentCategoryId.isNotEmpty) {
        final rawName = subMatch.group(1)!.trim();
        final slug = SlugGenerator.generate('$currentCategoryName $rawName'); // Global unique slug
        
        final docRef = subCategoriesCol.doc(slug);
        
        final aliases = AliasGenerator.getAliases(rawName);
        final tags = TagMapper.autoMapTagsForCategory(currentCategoryName);
        
        final keywords = KeywordGenerator.generateForEntity(
          name: rawName,
          categoryName: currentCategoryName,
          aliases: aliases,
          tags: tags,
        );

        final subCatModel = SubCategoryModel(
          subCategoryId: slug,
          categoryId: currentCategoryId,
          name: rawName,
          slug: slug,
          description: 'Authentic homemade $rawName',
          imageUrl: 'https://placehold.co/400x400/81C784/FFFFFF/png?text=${Uri.encodeComponent(rawName)}', // Fallback
          image: {
            'thumb': 'https://placehold.co/150x150/81C784/FFFFFF/png?text=${Uri.encodeComponent(rawName)}',
            'medium': 'https://placehold.co/400x400/81C784/FFFFFF/png?text=${Uri.encodeComponent(rawName)}',
            'large': 'https://placehold.co/800x800/81C784/FFFFFF/png?text=${Uri.encodeComponent(rawName)}',
          },
          productsCount: 0,
          storesCount: 0,
          tagsCount: tags.length,
          isPopular: sortOrder <= 3, // mark first 3 as popular
          isActive: true,
          sortOrder: sortOrder,
          aliases: aliases,
          searchKeywords: keywords,
          createdBySeeder: true,
        );

        batch.set(docRef, subCatModel.toJson(), SetOptions(merge: true));
        sortOrder++;
        count++;

        // Firestore batch limit is 500 operations. We use 250 to be safe.
        if (count >= 250) {
           await batch.commit();
           batch = firestore.batch();
           print('   Batch commit at $count...');
           count = 0;
        }
      }
    }

    if (count > 0) {
      await batch.commit();
    }
    print('✅ Successfully seeded $count sub-categories.');
  }
}
