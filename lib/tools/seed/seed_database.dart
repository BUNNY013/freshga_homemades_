import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'data/image_constants.dart';
import 'data/mock_data_generator.dart';

class DatabaseSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  /// Core helper to execute batched writes safely
  Future<void> _commitBatches(List<Map<String, dynamic>> items, String collectionPath, {String Function(int)? idGenerator}) async {
    int count = 0;
    WriteBatch batch = _db.batch();

    for (int i = 0; i < items.length; i++) {
      String docId = idGenerator != null ? idGenerator(i) : _db.collection(collectionPath).doc().id;
      DocumentReference docRef = _db.collection(collectionPath).doc(docId);
      batch.set(docRef, items[i]);
      count++;

      // Firestore limit is 500 operations per batch
      if (count == 400) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
        debugPrint('Committed 400 items to $collectionPath');
      }
    }

    if (count > 0) {
      await batch.commit();
      debugPrint('Committed remaining $count items to $collectionPath');
    }
  }

  /// Clears ONLY seeded data across all relevant collections
  Future<void> clearSeededData() async {
    for (String collection in _collectionsToClear) {
      final snapshot = await _db.collection(collection).where('createdBySeeder', isEqualTo: true).get();
      
      if (snapshot.docs.isEmpty) continue;

      WriteBatch batch = _db.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;

        if (count == 400) {
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
    int index = 1;
    final extraCategories = [
      'Organic Foods', 'Healthy Foods', 'Traditional Foods', 'Festival Specials', 
      'Ready Mixes', 'Instant Foods', 'Spice Powders', 'Herbal Wellness', 
      'Homemade Chocolates', 'Bakery', 'Breakfast Foods', 'Regional Foods', 
      'Andhra Specials', 'Tamil Specials', 'Kerala Specials', 'Ghee & Butter'
    ];
    
    // First add the categories from images
    ImageConstants.categoryImages.forEach((name, url) {
      cats.add(_buildCategoryMap(name, url, index++));
    });

    // Add extra categories to reach 30+
    for (String name in extraCategories) {
      String fallbackUrl = ImageConstants.categoryImages.values.elementAt((index) % ImageConstants.categoryImages.length);
      cats.add(_buildCategoryMap(name, fallbackUrl, index++));
    }

    await _commitBatches(cats, 'categories', idGenerator: (i) => cats[i]['categoryId']);
  }

  Map<String, dynamic> _buildCategoryMap(String name, String url, int index) {
    return {
      'categoryId': name.toLowerCase().replaceAll(' ', '_').replaceAll('&', 'and'),
      'name': name,
      'slug': name.toLowerCase().replaceAll(' ', '-').replaceAll('&', 'and'),
      'imageUrl': url,
      'isActive': true,
      'order': index,
      'tags': [name.toLowerCase(), 'homemade'],
      'keywords': [name.toLowerCase(), 'fresh'],
      'itemCount': 50 + (index * 12),
      'color': '#FFF9EE',
      'iconType': 'default',
      'createdBySeeder': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> seedSubcategories() async {
    final subCats = [
      {'categoryId': 'pickles', 'name': 'Mango Pickles'},
      {'categoryId': 'pickles', 'name': 'Garlic Pickles'},
      {'categoryId': 'pickles', 'name': 'Gongura Pickles'},
      {'categoryId': 'pickles', 'name': 'Lemon Pickles'},
      {'categoryId': 'pickles', 'name': 'Amla Pickles'},
      {'categoryId': 'snacks', 'name': 'Murukku'},
      {'categoryId': 'snacks', 'name': 'Mixture'},
      {'categoryId': 'snacks', 'name': 'Namkeen'},
      {'categoryId': 'snacks', 'name': 'Chips'},
      {'categoryId': 'cookies', 'name': 'Millet Cookies'},
      {'categoryId': 'cookies', 'name': 'Butter Cookies'},
      {'categoryId': 'cookies', 'name': 'Jaggery Cookies'},
      {'categoryId': 'sweets', 'name': 'Laddu'},
      {'categoryId': 'sweets', 'name': 'Halwa'},
      {'categoryId': 'sweets', 'name': 'Mysore Pak'},
      {'categoryId': 'masalas', 'name': 'Curry Powders'},
      {'categoryId': 'masalas', 'name': 'Spice Mixes'},
      {'categoryId': 'masalas', 'name': 'Karam Powders'},
    ];

    List<Map<String, dynamic>> items = [];
    for (int i = 0; i < 100; i++) {
      final template = subCats[i % subCats.length];
      String subId = '${template['categoryId']}_sub_$i';
      items.add({
        'subCategoryId': subId,
        'categoryId': template['categoryId'],
        'name': '${template['name']} $i',
        'imageUrl': ImageConstants.categoryImages.values.elementAt(i % ImageConstants.categoryImages.length),
        'isActive': true,
        'sortOrder': i,
        'createdBySeeder': true,
      });
    }

    await _commitBatches(items, 'subcategories');
  }

  Future<void> seedBanners() async {
    final titles = [
      'Mango Pickle Season', 'Summer Honey Festival', 'Traditional Homemade Snacks', 
      'Healthy Homemade Living', 'Organic Goodness Delivered', 'Festival Sweet Collections',
      'Weekend Special Offers', 'Grandma\'s Best Recipes', 'Pure Forest Honey', 'Spicy Andhra Powders'
    ];
    
    List<Map<String, dynamic>> banners = [];
    for (int i = 0; i < 20; i++) {
      banners.add(MockDataGenerator.generateBannerData(
        i + 1, 
        titles[i % titles.length] + (i > 9 ? ' $i' : ''), 
        'Discover authentic homemade tastes curated for you.', 
        'PREMIUM'
      ));
    }

    await _commitBatches(banners, 'banners');
  }

  Future<void> seedCollections() async {
    final titles = [
      'Summer Specials', 'Traditional Favorites', 'Festival Sweets', 'Healthy Living', 
      'Organic Essentials', 'Best Sellers', 'Trending This Week', 'Homemade Classics',
      'Andhra Special Picks', 'Breakfast Essentials', 'Tea Time Snacks', 'Village Homemade Foods'
    ];
    List<Map<String, dynamic>> items = [];
    
    for (int i = 0; i < 25; i++) {
      items.add({
        'title': titles[i % titles.length] + ' $i',
        'subtitle': 'Curated selections just for you',
        'bannerImage': ImageConstants.collectionBanners[i % ImageConstants.collectionBanners.length],
        'productIds': [], // Populated dynamically in real app
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
    final sectionTypes = ['heroBanner', 'categories', 'featuredStores', 'trendingProducts', 'recommendedProducts', 'collections', 'trustStrip'];
    
    List<Map<String, dynamic>> items = [];
    for (int i = 0; i < 15; i++) {
      String type = sectionTypes[i % sectionTypes.length];
      items.add({
        'type': type,
        'title': 'Discover $type ${i + 1}',
        'subtitle': 'Handpicked premium items',
        'order': i + 1,
        'isActive': true,
        'createdBySeeder': true,
      });
    }

    await _commitBatches(items, 'home_sections');
  }

  Future<void> seedStoresAndProducts() async {
    // Generate 100 stores, 10 products each = 1000 products
    List<Map<String, dynamic>> stores = [];
    List<Map<String, dynamic>> products = [];
    final categoryKeys = ImageConstants.categoryImages.keys.toList();

    for (int s = 0; s < 100; s++) {
      String storeId = 'mock_store_$s';
      String ownerId = 'mock_owner_$s';
      var storeData = MockDataGenerator.generateStoreData(storeId, ownerId);
      stores.add(storeData);

      for (int p = 0; p < 10; p++) {
        String productId = 'mock_prod_${s}_$p';
        String catName = categoryKeys[(s + p) % categoryKeys.length];
        String catId = catName.toLowerCase().replaceAll(' ', '_');

        products.add(MockDataGenerator.generateProductData(
          productId: productId,
          storeId: storeId,
          storeName: storeData['storeName'],
          categoryId: catId,
          subCategoryId: '${catId}_sub_1',
        ));
      }
    }

    await _commitBatches(stores, 'stores', idGenerator: (i) => stores[i]['storeId']);
    await _commitBatches(products, 'products', idGenerator: (i) => products[i]['productId']);
  }

  /// Master method to run the entire seeder
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
