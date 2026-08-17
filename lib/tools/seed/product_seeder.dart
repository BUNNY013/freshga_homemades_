import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';
import '../../models/subcategory_model.dart';
import 'data/mock_data_generator.dart';
import 'utils/keyword_generator.dart';
import 'utils/tag_mapper.dart';

class ProductSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Random _random = Random();

  static Future<void> seedStoresAndProducts() async {
    print('🛒 Seeding Stores and Products guaranteed for every subcategory...');

    // 1. Fetch exact categories and subcategories that were just seeded
    final catsSnapshot = await _db.collection('categories').where('createdBySeeder', isEqualTo: true).get();
    final subsSnapshot = await _db.collection('sub_categories').where('createdBySeeder', isEqualTo: true).get();

    if (catsSnapshot.docs.isEmpty) {
      print('❌ No categories found. Run category seeder first.');
      return;
    }

    final categories = catsSnapshot.docs.map((d) => CategoryModel.fromJson(d.data(), d.id)).toList();
    final subcategories = subsSnapshot.docs.map((d) => SubCategoryModel.fromJson(d.data(), d.id)).toList();

    List<Map<String, dynamic>> stores = [];
    List<Map<String, dynamic>> products = [];
    List<Map<String, dynamic>> subscriptions = [];
    
    // Create batches
    var batch = _db.batch();
    int count = 0;

    // Generate 20 stores
    for (int s = 0; s < 20; s++) {
      String storeId = 'mock_store_$s';
      String ownerId = 'mock_owner_$s';
      
      var storeData = MockDataGenerator.generateStoreData(storeId, ownerId);
      storeData['categories'] = []; // We will dynamically assign this based on products
      storeData['createdBySeeder'] = true;
      stores.add(storeData);

      // Generate subscription data for this store
      var subData = MockDataGenerator.generateVendorSubscriptionData(storeId);
      subscriptions.add(subData);
    }

    int productCounter = 0;

    // GUARANTEE: Iterate over EVERY SINGLE subcategory and create a product for it
    for (var sub in subcategories) {
      // Pick a random store to sell this product
      var store = stores[_random.nextInt(stores.length)];
      
      String productId = 'mock_prod_${productCounter++}';
      
      // Find parent category
      final cat = categories.firstWhere((c) => c.categoryId == sub.categoryId, orElse: () => categories.first);
      
      // Add category to store's list if not present
      if (!(store['categories'] as List).contains(cat.name)) {
         (store['categories'] as List).add(cat.name);
      }

      // Apply intelligent tags and keywords
      final tags = TagMapper.autoMapTagsForCategory(cat.name);
      
      // Generate realistic name based exactly on the subcategory
      String productName = 'Homemade ${sub.name}';
      
      final keywords = KeywordGenerator.generateForEntity(
        name: productName,
        categoryName: cat.name,
        tags: tags,
      );

      final productData = MockDataGenerator.generateProductData(
        productId: productId,
        storeId: store['storeId'],
        storeName: store['storeName'],
        categoryId: cat.categoryId,
        categoryName: cat.name,
        subCategoryIds: [sub.subCategoryId],
      );
      
      // Enhance product data with exact names and keywords
      productData['name'] = productName;
      productData['tags'] = tags;
      productData['searchKeywords'] = keywords;
      productData['createdBySeeder'] = true;
      
      products.add(productData);
    }

    // Add stores to batch
    for (var store in stores) {
      batch.set(_db.collection('stores').doc(store['storeId']), store);
      count++;
      if (count >= 100) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }
    
    // Add products to batch
    for (var product in products) {
      batch.set(_db.collection('products').doc(product['productId']), product);
      count++;
      if (count >= 100) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }

    // Add subscriptions to batch
    for (var sub in subscriptions) {
      batch.set(_db.collection('store_subscriptions').doc(sub['storeId']), sub);
      count++;
      if (count >= 100) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }

    print('✅ Successfully seeded ${stores.length} stores, ${subscriptions.length} subscriptions, and ${products.length} products! Every subcategory now has at least 1 product.');
  }
}
