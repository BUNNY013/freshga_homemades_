import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'data/image_constants.dart';
import 'data/mock_data_generator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();

  final List<String> _collectionsToClear = [
    'banners',
    // 'categories', // Removed so we don't accidentally wipe categories the user edited in Admin app
    // 'subcategories', 
    'stores',
    'products',
    'collections',
    'trust_features',
    'home_sections',
    'store_updates',
    'appConfig',
    'followers',
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
    final sectionsData = [
      {'type': 'heroBanner', 'title': ''},
      {'type': 'categories', 'title': 'Shop by Categories'},
      {'type': 'trustStrip', 'title': ''},
      {'type': 'followingStores', 'title': 'Following Stores'},
      {'type': 'storeUpdates', 'title': 'Latest From Stores You Follow'},
      {'type': 'localBrands', 'title': 'Homemade Brands Around You'},
      {'type': 'newStores', 'title': 'New Homemade Brands'},
      {'type': 'featuredStores', 'title': 'Featured Stores'},
    ];
    
    List<Map<String, dynamic>> items = [];
    for (int i = 0; i < sectionsData.length; i++) {
      items.add({
        'type': sectionsData[i]['type'],
        'title': sectionsData[i]['title'],
        'subtitle': '',
        'order': i + 1,
        'isActive': true,
        'createdBySeeder': true,
      });
    }

    await _commitBatches(items, 'home_sections');
  }

  Future<void> seedAppConfig() async {
    final bannerData = {
      'title': "Can’t find what you’re looking for?",
      'subtitle': "Request a product from your favourite stores.",
      'buttonText': "Request Now",
      'imageUrl': "https://firebasestorage.googleapis.com/v0/b/freshga-homemades.firebasestorage.app/o/mock_data%2Fcategories%2Fpickles.png?alt=media",
      'isActive': true,
      'link': "",
      'createdBySeeder': true,
    };

    await _db.collection('appConfig').doc('categories_banner').set(bannerData);
    debugPrint('Seeded appConfig/categories_banner');
  }

  Future<void> seedStoresAndProducts() async {
    List<Map<String, dynamic>> stores = [];
    List<Map<String, dynamic>> products = [];

    // Fetch real categories and subcategories from the database to map products correctly
    final catsSnapshot = await _db.collection('categories').get();
    final subsSnapshot = await _db.collection('sub_categories').get();
    
    List<Map<String, dynamic>> realCats = catsSnapshot.docs.map((d) {
      final data = d.data();
      data['categoryId'] = d.id;
      return data;
    }).toList();
    
    List<Map<String, dynamic>> realSubs = subsSnapshot.docs.map((d) {
      final data = d.data();
      data['subCategoryId'] = d.id;
      return data;
    }).toList();

    // If no real categories exist, we cannot map them properly. Let's fallback to the dummy ones if needed, 
    // but ideally the user has categories.
    if (realCats.isEmpty) {
      debugPrint("WARNING: No real categories found. Products might not map correctly. Run seedCategories first or create them in Admin app.");
    }

    // 20 Stores, ~20 products each
    for (int s = 0; s < 20; s++) {
      String storeId = 'mock_store_$s';
      String ownerId = 'mock_owner_$s';
      var storeData = MockDataGenerator.generateStoreData(storeId, ownerId);
      stores.add(storeData);

      // We select 2-3 random categories for this store to specialize in
      List<Map<String, dynamic>> storeCategories = [];
      if (realCats.isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          storeCategories.add(realCats[_random.nextInt(realCats.length)]);
        }
        // Unique by ID
        final uniqueCats = <String, Map<String, dynamic>>{};
        for (var cat in storeCategories) {
          uniqueCats[cat['categoryId']] = cat;
        }
        storeCategories = uniqueCats.values.toList();
      }

      for (int p = 0; p < 20; p++) {
        String productId = 'mock_prod_${s}_$p';
        
        String catId = '';
        String catName = 'Uncategorized';
        List<String> selectedSubs = [];

        if (storeCategories.isNotEmpty) {
          final cat = storeCategories[_random.nextInt(storeCategories.length)];
          catId = cat['categoryId'];
          catName = cat['name'] ?? 'Unknown';
          
          // Find real subcategories that belong to this category
          List<Map<String, dynamic>> availableSubs = realSubs.where((sub) => sub['categoryId'] == catId).toList();
          
          if (availableSubs.isNotEmpty) {
            availableSubs.shuffle();
            selectedSubs = availableSubs.take(2).map((sub) => sub['subCategoryId'] as String).toList();
          }
        } else {
          // Fallback logic if db is completely empty
          catName = _mainCategories[_random.nextInt(_mainCategories.length)];
          catId = catName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_');
          List<String> availableSubs = _subcategoriesMap[catId] ?? _subcategoriesMap['default']!;
          availableSubs.shuffle();
          selectedSubs = availableSubs.take(2).map((subName) {
             return '${catId}_${subName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_')}';
          }).toList();
        }

        products.add(MockDataGenerator.generateProductData(
          productId: productId,
          storeId: storeId,
          storeName: storeData['storeName'],
          categoryId: catId,
          categoryName: catName,
          subCategoryIds: selectedSubs,
          canSellPanIndia: storeData['canSellPanIndia'] ?? false,
          state: storeData['state'] ?? '',
        ));
      }
    }

    await _commitBatches(stores, 'stores', idGenerator: (i) => stores[i]['storeId']);
    await _commitBatches(products, 'products', idGenerator: (i) => products[i]['productId']);
  }

  Future<void> seedStoreUpdates() async {
    debugPrint("Seeding store updates...");
    final storesSnapshot = await _db.collection('stores').where('createdBySeeder', isEqualTo: true).get();
    final productsSnapshot = await _db.collection('products').where('createdBySeeder', isEqualTo: true).get();
    
    if (storesSnapshot.docs.isEmpty) return;

    List<Map<String, dynamic>> updates = [];

    // Group products by storeId
    Map<String, List<QueryDocumentSnapshot>> storeProducts = {};
    for (var doc in productsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String sId = data['storeId'] ?? '';
      storeProducts.putIfAbsent(sId, () => []).add(doc);
    }

    for (var storeDoc in storesSnapshot.docs) {
      final storeData = storeDoc.data() as Map<String, dynamic>;
      final products = storeProducts[storeDoc.id] ?? [];

      for (int i = 0; i < 25; i++) {
        int roll = _random.nextInt(100);
        String type;
        String title = '';
        String description = '';
        String badgeText = '';
        String ctaText = '';
        String? productId;
        String? productName;
        double price = 0;
        double discountPrice = 0;
        String imageUrl = storeData['storeBanner'] ?? storeData['storeLogo'] ?? '';

        var p = products.isNotEmpty ? products[_random.nextInt(products.length)].data() as Map<String, dynamic>? : null;

        if (roll < 40) {
          type = 'new_launch';
          badgeText = 'New Launch';
          ctaText = 'Buy Now';
          if (p != null) {
            productId = p['productId'];
            productName = p['name'];
            price = (p['price'] ?? 0).toDouble();
            discountPrice = (p['discountPrice'] ?? 0).toDouble();
            title = "$productName Fresh Batch Available!";
            description = "We just finished preparing a fresh batch of $productName. Order now while stocks last!";
            imageUrl = (p['images'] as List).isNotEmpty ? p['images'][0] : imageUrl;
          } else {
            title = "New Product Launched!";
            description = "Check out our latest homemade creation, prepared with love and authentic ingredients.";
          }
        } else if (roll < 60) {
          type = 'restock';
          badgeText = 'Restocked';
          ctaText = 'Order Again';
          if (p != null) {
            productId = p['productId'];
            productName = p['name'];
            price = (p['price'] ?? 0).toDouble();
            discountPrice = (p['discountPrice'] ?? 0).toDouble();
            title = "$productName is Back in Stock!";
            description = "You asked, we listened! $productName is back in stock. Grab yours before it runs out again.";
            imageUrl = (p['images'] as List).isNotEmpty ? p['images'][0] : imageUrl;
          } else {
            title = "Favorites Restocked!";
            description = "Your favorite homemade treats are back in stock. Order now!";
          }
        } else if (roll < 80) {
          type = 'offer';
          badgeText = 'Offer';
          ctaText = 'Claim Offer';
          if (p != null) {
            productId = p['productId'];
            productName = p['name'];
            price = (p['price'] ?? 0).toDouble();
            discountPrice = price * 0.9;
            title = "10% OFF on $productName!";
            description = "Special weekend offer! Get 10% off on your favorite $productName. Use code FRESH10.";
            imageUrl = (p['images'] as List).isNotEmpty ? p['images'][0] : imageUrl;
          } else {
            title = "Weekend Special Discount!";
            description = "Get 10% off on all orders this weekend. Limited time offer!";
          }
        } else {
          type = 'community_update';
          badgeText = 'Update';
          ctaText = 'View Store';
          title = "Fresh season updates from ${storeData['storeName']}";
          description = "We are preparing exciting new recipes this season. Stay tuned for our upcoming launches!";
        }

        final daysAgo = _random.nextInt(30);
        final hoursAgo = _random.nextInt(24);
        final date = DateTime.now().subtract(Duration(days: daysAgo, hours: hoursAgo));

        String updateId = _db.collection('store_updates').doc().id;

        updates.add({
          'updateId': updateId,
          'storeId': storeDoc.id,
          'storeName': storeData['storeName'] ?? '',
          'storeLogo': storeData['storeLogo'] ?? '',
          'storeBanner': storeData['storeBanner'] ?? '',
          'type': type,
          'title': title,
          'description': description,
          'imageUrl': imageUrl,
          if (productId != null) 'productId': productId,
          if (productName != null) 'productName': productName,
          'price': price,
          'discountPrice': discountPrice,
          'ctaText': ctaText,
          'badgeText': badgeText,
          'isActive': true,
          'createdBySeeder': true,
          'createdAt': Timestamp.fromDate(date),
          'updatedAt': Timestamp.fromDate(date),
        });
      }
    }

    await _commitBatches(updates, 'store_updates', idGenerator: (i) => updates[i]['updateId']);
  }

  Future<void> runFullSeed() async {
    debugPrint("Starting full database seed...");
    // await seedCategories(); // Disabled to preserve real categories
    // await seedSubcategories(); // Disabled to preserve real subcategories
    await seedBanners();
    await seedCollections();
    await seedTrustFeatures();
    await seedHomeSections();
    await seedAppConfig();
    await seedStoresAndProducts();
    await seedStoreUpdates();
    await seedFollowers();
    debugPrint("Finished database seed.");
  }

  Future<void> seedFollowers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("No logged in user found. Skipping followers seed.");
      return;
    }

    final storeSnapshot = await _db.collection('stores').where('createdBySeeder', isEqualTo: true).limit(5).get();
    if (storeSnapshot.docs.isEmpty) return;

    WriteBatch batch = _db.batch();
    
    for (var doc in storeSnapshot.docs) {
      final storeData = doc.data();
      final userStoreRef = _db.collection('users').doc(user.uid).collection('followingStores').doc(doc.id);
      final storeFollowerRef = _db.collection('stores').doc(doc.id).collection('followers').doc(user.uid);
      final storeRef = _db.collection('stores').doc(doc.id);

      batch.set(userStoreRef, {
        'storeId': doc.id,
        'storeName': storeData['storeName'] ?? '',
        'storeLogo': storeData['logo'] ?? '',
        'followedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': true,
        'createdBySeeder': true,
      });

      batch.set(storeFollowerRef, {
        'userId': user.uid,
        'userName': user.displayName ?? 'Customer',
        'userProfileImage': user.photoURL ?? '',
        'followedAt': FieldValue.serverTimestamp(),
        'createdBySeeder': true,
      });

      batch.update(storeRef, {'followers': FieldValue.increment(1)});
    }

    await batch.commit();
    debugPrint("Seeded mock followers for user ${user.uid}");
  }
}
