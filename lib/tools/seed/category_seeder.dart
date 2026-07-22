import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';
import 'utils/slug_generator.dart';
import 'utils/keyword_generator.dart';
import 'data/categories_data.dart';

class CategorySeeder {
  static Future<void> seedCategories() async {
    print('📦 Seeding categories from Dart constant...');
    
    final lines = categoriesRawData.split('\n');
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final categoriesCol = firestore.collection('categories');

    final categoryRegex = RegExp(r'(?:[\u2700-\u27BF]|[\uE000-\uF8FF]|\uD83C[\uDC00-\uDFFF]|\uD83D[\uDC00-\uDFFF]|[\u2011-\u26FF]|\uD83E[\uDD10-\uDDFF])?\s*\d+\.\s+(.*)');

    int sortOrder = 1;
    int count = 0;

    for (var line in lines) {
      final match = categoryRegex.firstMatch(line.trim());
      if (match != null) {
        final rawName = match.group(1)!.trim();
        final slug = SlugGenerator.generate(rawName);
        
        final docRef = categoriesCol.doc(slug);
        
        final keywords = KeywordGenerator.generateForEntity(name: rawName);

        final catModel = CategoryModel(
          categoryId: slug,
          name: rawName,
          slug: slug,
          description: 'Explore the best homemade $rawName',
          image: {
            'url': 'https://placehold.co/400x400/2E7D32/FFFFFF/png?text=${Uri.encodeComponent(rawName)}',
            'storagePath': '',
          },
          banner: {
            'url': 'https://placehold.co/800x600/1B5E20/FFFFFF/png?text=${Uri.encodeComponent(rawName)}', 
          },
          itemCount: 0,
          status: 'active',
          isFeatured: sortOrder <= 5, // feature first 5
          displayIndex: sortOrder,
          analytics: {'productsCount': 0, 'storesCount': 0},
          metadata: {'createdBy': 'seeder', 'updatedBy': 'seeder'},
          searchKeywords: keywords,
          createdBySeeder: true,
        );

        batch.set(docRef, catModel.toJson(), SetOptions(merge: true));
        sortOrder++;
        count++;
      }
    }

    await batch.commit();
    print('✅ Successfully seeded $count categories.');
  }
}
