import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_seeder.dart';
import 'subcategory_seeder.dart';
import 'tags_seeder.dart';
import 'product_seeder.dart';
import '../../firebase_options.dart';

/// Runner script to execute all seeders in order.
/// Usage: 
/// 1. Make sure you have a valid Firebase configuration.
/// 2. Run this script directly or call `runSeeders()` from a hidden dev menu.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await runSeeders();
}

Future<void> clearOldData() async {
  print('🧹 Clearing old generated data (categories, tags, stores, products)...');
  final db = FirebaseFirestore.instance;
  final collections = ['categories', 'sub_categories', 'subcategories', 'tags', 'stores', 'products', 'store_subscriptions'];
  
  for (String col in collections) {
    final snapshot = await db.collection(col).where('createdBySeeder', isEqualTo: true).get();
    if (snapshot.docs.isNotEmpty) {
      var batch = db.batch();
      int count = 0;
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        if (count == 100) {
          await batch.commit();
          batch = db.batch();
          count = 0;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
      print('  - Cleared ${snapshot.docs.length} from $col');
    }
  }
}

Future<void> runSeeders() async {
  print('====================================');
  print('🚀 STARTING FRESHGA SEEDER SYSTEM');
  print('====================================');

  try {
    // 0. Clear old ones first
    await clearOldData();

    // 1. Seed Categories
    await CategorySeeder.seedCategories();

    // 2. Seed Sub Categories
    await SubCategorySeeder.seedSubCategories();

    // 3. Seed Tags
    await TagsSeeder.seedTags();

    // 4. Seed Stores & Products mapping directly to new categories
    await ProductSeeder.seedStoresAndProducts();

    print('====================================');
    print('🎉 ALL SEEDING COMPLETED SUCCESSFULLY');
    print('====================================');
  } catch (e, stack) {
    print('❌ Seeder failed: \$e');
    print(stack);
  }
}
