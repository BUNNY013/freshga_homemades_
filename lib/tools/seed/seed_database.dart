import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'data/image_constants.dart';
import 'data/mock_data_generator.dart';

class DatabaseSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();

  final List<String> _collectionsToClear = [
    'banners',
    'categories',
    'subcategories',
    'stores',
    'products',
    'collections',
    'trust_features',
    'home_sections',
  ];

  final List<String> _mainCategories = [
    'Pickles', 'Honey', 'Cookies & Biscuits', 'Snacks', 'Sweets', 
    'Masalas & Powders', 'Chutneys & Spreads', 'Millet & Healthy Foods', 
    'Beverages & Mixes', 'Ready-to-Cook', 'Homemade Powders & Podis', 
    'Dry Fruits & Nuts', 'Oils & Ghee', 'Herbal & Ayurvedic Products', 
    'Bakery Items', 'Papads & Fryums', 'Homemade Sauces & Syrups', 
    'Breakfast Essentials', 'Gift Hampers', 'Regional Specialties'
  ];

  final Map<String, List<String>> _subcategoriesMap = {
    'pickles': ['Veg Pickles', 'Non Veg Pickles', 'Andhra Pickles', 'Traditional Pickles', 'Spicy Pickles', 'Oil-Free Pickles'],
    'honey': ['Raw Honey', 'Forest Honey', 'Organic Honey', 'Herbal Honey'],
    'snacks': ['Namkeen', 'Murukku & Chakli', 'Mixture', 'Chips'],
    'sweets': ['Dry Sweets', 'Jaggery Sweets', 'Laddu Varieties'],
    'masalas_and_powders': ['Curry Powders', 'Biryani Masala', 'Sambar Powder', 'Rasam Powder', 'Karam Podi'],
    'millet_and_healthy_foods': ['Millet Noodles', 'Millet Snacks', 'Health Mixes'],
    // Add generic subcategories for others just to ensure data exists
    'default': ['Premium Quality', 'Homemade Classics', 'Best Sellers', 'Organic Picks']
  };

  Future<void> _commitBatches(List<Map<String, dynamic>> items, String collectionPath, {String Function(int)? idGenerator}) async {
    int count = 0;
    WriteBatch batch = _db.batch();

    for (int i = 0; i < items.length; i++) {
      String docId = idGenerator != null ? idGenerator(i) : _db.collection(collectionPath).doc().id;
      DocumentReference docRef = _db.collection(collectionPath).doc(docId);
      batch.set(docRef, items[i]);
      count++;

      if (count == 50) {
        try {
          await batch.commit();
        } catch (e) {
          debugPrint('Error committing batch in $collectionPath: $e');
          // Print the first item to see its structure
          debugPrint('First item in failing batch: ${items.first}');
          rethrow;
        }
        batch = _db.batch();
        count = 0;
        debugPrint('Committed 50 items to $collectionPath');
      }
    }

    if (count > 0) {
      try {
        await batch.commit();
      } catch (e) {
        debugPrint('Error committing final batch in $collectionPath: $e');
        debugPrint('First item in failing batch: ${items.first}');
        rethrow;
      }
      debugPrint('Committed remaining $count items to $collectionPath');
    }
  }

  Future<void> clearSeededData() async {
    for (String collection in _collectionsToClear) {
      final snapshot = await _db.collection(collection).where('createdBySeeder', isEqualTo: true).get();
      if (snapshot.docs.isEmpty) continue;

      WriteBatch batch = _db.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;

        if (count == 50) {
          await batch.commit();
          batch = _db.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }
      debugPrint('Cleared seeded data from $collection');
    }
  }

  Future<void> seedCategories() async {
    List<Map<String, dynamic>> cats = [];
    
    for (int i = 0; i < _mainCategories.length; i++) {
      String name = _mainCategories[i];
      String id = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_');
      String slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-').replaceAll(RegExp(r'-+'), '-');
      
      String fallbackUrl = ImageConstants.categoryImages.values.elementAt(i % ImageConstants.categoryImages.length);

      cats.add({
        'categoryId': id,
        'name': name,
        'slug': slug,
        'imageUrl': fallbackUrl,
        'isActive': true,
        'sortOrder': i + 1,
        'createdBySeeder': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await _commitBatches(cats, 'categories', idGenerator: (i) => cats[i]['categoryId']);
  }

  Future<void> seedSubcategories() async {
    List<Map<String, dynamic>> items = [];
    int sortCounter = 1;

    for (int i = 0; i < _mainCategories.length; i++) {
      String catName = _mainCategories[i];
      String catId = catName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_');
      
      List<String> subCats = _subcategoriesMap[catId] ?? _subcategoriesMap['default']!;

      for (String subName in subCats) {
        String subId = '${catId}_${subName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_')}';
        String slug = subName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-').replaceAll(RegExp(r'-+'), '-');
        
        items.add({
          'subCategoryId': subId,
          'categoryId': catId,
          'name': subName,
          'slug': slug,
          'isActive': true,
          'sortOrder': sortCounter++,
          'createdBySeeder': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await _commitBatches(items, 'subcategories', idGenerator: (i) => items[i]['subCategoryId']);
  }

  Future<void> seedBanners() async {
    final titles = [
      'Mango Pickle Season', 'Summer Honey Festival', 'Traditional Homemade Snacks', 
      'Healthy Homemade Living', 'Organic Goodness Delivered', 'Festival Sweet Collections',
    ];
    
    List<Map<String, dynamic>> banners = [];
    for (int i = 0; i < 6; i++) {
      banners.add(MockDataGenerator.generateBannerData(
        i + 1, 
        titles[i % titles.length], 
        'Discover authentic homemade tastes curated for you.', 
        'PREMIUM'
      ));
    }

    await _commitBatches(banners, 'banners');
  }

  Future<void> seedCollections() async {
    final titles = [
      'Summer Specials', 'Traditional Favorites', 'Festival Sweets', 'Healthy Living', 
    ];
    List<Map<String, dynamic>> items = [];
    
    for (int i = 0; i < 4; i++) {
      items.add({
        'title': titles[i % titles.length],
        'subtitle': 'Curated selections just for you',
        'bannerImage': ImageConstants.collectionBanners[i % ImageConstants.collectionBanners.length],
        'productIds': [],
        'isActive': true,
        'createdBySeeder': true,
      });
    }
    
    await _commitBatches(items, 'collections');
  }

  Future<void> seedTrustFeatures() async {
    final features = [
      {'title': 'Verified Sellers', 'subtitle': '100% trusted'},
      {'title': 'No Preservatives', 'subtitle': 'Homemade & Pure'},
      {'title': 'Eco Packaging', 'subtitle': 'Better for Earth'},
      {'title': 'On-time Dispatch', 'subtitle': 'Fresh to you'},
    ];

    List<Map<String, dynamic>> items = features.map((f) => {
      ...f,
      'createdBySeeder': true,
      'order': features.indexOf(f),
      'isActive': true,
    }).toList();

    await _commitBatches(items, 'trust_features');
  }

  Future<void> seedHomeSections() async {
    final sectionTypes = ['heroBanner', 'categories', 'featuredStores', 'trendingProducts'];
    
    List<Map<String, dynamic>> items = [];
    for (int i = 0; i < sectionTypes.length; i++) {
      String type = sectionTypes[i];
      items.add({
        'type': type,
        'title': 'Discover $type',
        'subtitle': 'Handpicked premium items',
        'order': i + 1,
        'isActive': true,
        'createdBySeeder': true,
      });
    }

    await _commitBatches(items, 'home_sections');
  }

  Future<void> seedStoresAndProducts() async {
    List<Map<String, dynamic>> stores = [];
    List<Map<String, dynamic>> products = [];

    // 20 Stores, ~20 products each
    for (int s = 0; s < 20; s++) {
      String storeId = 'mock_store_$s';
      String ownerId = 'mock_owner_$s';
      var storeData = MockDataGenerator.generateStoreData(storeId, ownerId);
      stores.add(storeData);

      // We select 2-3 random categories for this store to specialize in
      List<String> storeCategories = [];
      for (int i = 0; i < 3; i++) {
        storeCategories.add(_mainCategories[_random.nextInt(_mainCategories.length)]);
      }
      storeCategories = storeCategories.toSet().toList(); // Unique

      for (int p = 0; p < 20; p++) {
        String productId = 'mock_prod_${s}_$p';
        String catName = storeCategories[_random.nextInt(storeCategories.length)];
        String catId = catName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_');
        
        List<String> availableSubs = _subcategoriesMap[catId] ?? _subcategoriesMap['default']!;
        
        // Pick 2 random subcategories
        availableSubs.shuffle();
        List<String> selectedSubs = availableSubs.take(2).map((subName) {
           return '${catId}_${subName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_')}';
        }).toList();

        products.add(MockDataGenerator.generateProductData(
          productId: productId,
          storeId: storeId,
          storeName: storeData['storeName'],
          categoryId: catId,
          categoryName: catName,
          subCategoryIds: selectedSubs,
        ));
      }
    }

    await _commitBatches(stores, 'stores', idGenerator: (i) => stores[i]['storeId']);
    await _commitBatches(products, 'products', idGenerator: (i) => products[i]['productId']);
  }

  Future<void> runFullSeed() async {
    debugPrint("Starting full database seed...");
    await seedCategories();
    await seedSubcategories();
    await seedBanners();
    await seedCollections();
    await seedTrustFeatures();
    await seedHomeSections();
    await seedStoresAndProducts();
    debugPrint("Finished database seed.");
  }
}
