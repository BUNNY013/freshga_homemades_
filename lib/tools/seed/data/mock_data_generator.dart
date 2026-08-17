import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_constants.dart';
import '../../../core/utils/search_utils.dart';

class MockDataGenerator {
  static final Random _random = Random();

  static const List<String> storePrefixes = ['The Heritage', 'Organic', 'Grandma\'s', 'Amma\'s', 'NatureNest', 'Village Spice', 'Traditional', 'Pure Harvest', 'Rustic', 'Golden Harvest', 'Royal Andhra', 'Native', 'Green Earth', 'Millet', 'Spice'];
  static const List<String> storeSuffixes = ['Kitchen', 'Roots', 'Secrets', 'Pickles', 'Foods', 'House', 'Bowl', 'Recipes', 'Farm', 'Pantry', 'Tastes', 'Organics', 'Kingdom', 'Trails'];

  static const List<String> productPrefixes = ['Spicy', 'Wild Forest', 'Garlic', 'Millet', 'Traditional Ghee', 'Homemade', 'Dry Fruit', 'Masala', 'Premium', 'Authentic', 'Andhra', 'Nattu', 'Organic', 'Herbal', 'Traditional'];
  static const List<String> productBases = ['Mango Pickle', 'Honey', 'Chutney Powder', 'Laddu', 'Cookies', 'Amla Pickle', 'Murukku', 'Gongura Pickle', 'Peanuts', 'Mixture', 'Karivepaku Powder', 'Ragi Cookies', 'Jaggery', 'Avakaya', 'Mysore Pak', 'Sweets', 'Tea Mix'];

  static const List<String> tags = ['spicy', 'traditional', 'homemade', 'organic', 'fresh', 'healthy', 'sweet', 'savory', 'authentic', 'premium'];

  static String generateStoreName() {
    return '${storePrefixes[_random.nextInt(storePrefixes.length)]} ${storeSuffixes[_random.nextInt(storeSuffixes.length)]}';
  }

  static String generateStoreHandle(String name) {
    String formatted = name.toLowerCase().replaceAll(' ', '_');
    formatted = formatted.replaceAll(RegExp(r'[^a-z0-9_\.]'), '');
    return formatted;
  }

  static String generateSlug(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-').replaceAll(RegExp(r'-+'), '-');
  }

  // Mock Locations
  static const List<Map<String, String>> mockLocations = [
    {'businessAddress': 'Plot No 12, Jubilee Hills', 'village': 'Madhapur', 'district': 'Hyderabad', 'city': 'Hyderabad', 'state': 'Telangana', 'country': 'India', 'pincode': '500081'},
    {'businessAddress': 'D.No 4-5-6, Main Road', 'village': 'Gudlavalleru', 'district': 'Krishna', 'city': 'Gudlavalleru', 'state': 'Andhra Pradesh', 'country': 'India', 'pincode': '521356'},
    {'businessAddress': 'Beside RTC Bus Stand', 'village': 'Patamata', 'district': 'NTR', 'city': 'Vijayawada', 'state': 'Andhra Pradesh', 'country': 'India', 'pincode': '520001'},
    {'businessAddress': '1st Cross, Indiranagar', 'village': 'Indiranagar', 'district': 'Bengaluru Urban', 'city': 'Bangalore', 'state': 'Karnataka', 'country': 'India', 'pincode': '560001'},
    {'businessAddress': 'No 5, Anna Salai', 'village': 'T Nagar', 'district': 'Chennai', 'city': 'Chennai', 'state': 'Tamil Nadu', 'country': 'India', 'pincode': '600001'},
  ];

  static Map<String, dynamic> generateStoreData(String storeId, String ownerId) {
    final name = generateStoreName();
    final categories = ['Pickles', 'Snacks'];
    final storeSlug = generateStoreHandle(name);
    final searchableText = "$name $storeSlug ${categories.join(' ')}";
    final searchKeywords = SearchUtils.generateSearchKeywords(searchableText);
    final loc = mockLocations[_random.nextInt(mockLocations.length)];
    
    // Simulate GST vs Enrolment ID
    final bool isPanIndia = _random.nextDouble() > 0.5;
    final String taxRegType = isPanIndia ? 'GSTIN' : 'EnrolmentNumber';
    final String taxNumber = isPanIndia ? '27AAPFU0939F1Z5' : 'ENR1234567890';
    
    return {
      'storeId': storeId,
      'ownerId': ownerId,
      'storeName': name,
      'storeSlug': storeSlug,
      'description': 'Handcrafted with love. Traditional recipes passed down through generations.',
      'logo': ImageConstants.storeLogos[_random.nextInt(ImageConstants.storeLogos.length)],
      'banner': ImageConstants.storeBanners[_random.nextInt(ImageConstants.storeBanners.length)],
      'instagramLink': 'https://instagram.com/mock',
      'youtubeLink': '',
      'facebookLink': '',
      'categories': categories,
      'followers': _random.nextInt(5000),
      'likesCount': _random.nextInt(10000),
      'productsCount': _random.nextInt(50) + 5,
      'rating': double.parse((3.5 + _random.nextDouble() * 1.5).toStringAsFixed(1)),
      'totalReviews': _random.nextInt(500),
      'totalOrders': _random.nextInt(2000),
      'verified': true,
      'isFeatured': _random.nextDouble() > 0.5,
      'isActive': true,
      'dispatchTime': '${_random.nextInt(2) + 1}-${_random.nextInt(3) + 3} Days',
      'searchKeywords': searchKeywords,
      'canSellPanIndia': isPanIndia,
      'taxRegistrationType': taxRegType,
      'taxNumber': taxNumber,
      'businessAddress': loc['businessAddress'],
      'village': loc['village'],
      'city': loc['city'],
      'district': loc['district'],
      'state': loc['state'],
      'country': loc['country'],
      'pincode': loc['pincode'],
      'createdBySeeder': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // --- PRODUCT HELPERS ---
  static Map<String, dynamic> generateProductData({
    required String productId,
    required String storeId,
    required String storeName,
    required String categoryId,
    required String categoryName,
    required List<String> subCategoryIds,
    bool canSellPanIndia = false,
    String state = '',
  }) {
    final name = '${productPrefixes[_random.nextInt(productPrefixes.length)]} ${productBases[_random.nextInt(productBases.length)]}';
    final basePrice = 150 + _random.nextInt(400);
    
    final storeSlug = generateStoreHandle(storeName);
    
    final selectedTags = [tags[_random.nextInt(tags.length)], tags[_random.nextInt(tags.length)]];
    final searchableText = "$name $storeName $storeSlug $categoryName $categoryId ${subCategoryIds.join(' ')} ${selectedTags.join(' ')}";
    final searchKeywords = SearchUtils.generateSearchKeywords(searchableText);

    final totalReviews = _random.nextInt(200) + 10;
    
    int count5 = (totalReviews * (0.5 + _random.nextDouble() * 0.3)).toInt();
    int count4 = (totalReviews * (0.1 + _random.nextDouble() * 0.2)).toInt();
    int count3 = (totalReviews * (0.05 + _random.nextDouble() * 0.1)).toInt();
    int count2 = (totalReviews * (0.01 + _random.nextDouble() * 0.05)).toInt();
    int count1 = totalReviews - (count5 + count4 + count3 + count2);
    if (count1 < 0) count1 = 0;

    final ratingCounts = {
      "5": count5,
      "4": count4,
      "3": count3,
      "2": count2,
      "1": count1
    };

    double calculatedRating = totalReviews > 0 ? (count5 * 5 + count4 * 4 + count3 * 3 + count2 * 2 + count1 * 1) / totalReviews : 0.0;

    final allHighlights = ["Pure & Natural", "Great Taste", "Good Packaging", "Value for Money", "Authentic Recipe", "Fresh Ingredients"];
    allHighlights.shuffle();
    final numHighlights = _random.nextInt(3) + 2;
    final ratingHighlights = <String, int>{};
    for (int i = 0; i < numHighlights; i++) {
      ratingHighlights[allHighlights[i]] = _random.nextInt(totalReviews);
    }

    return {
      'productId': productId,
      'storeId': storeId,
      'storeName': storeName,
      'name': name,
      'slug': generateSlug(name) + '-$productId',
      'description': 'Authentic homemade $name made with premium ingredients and no preservatives. A perfect addition to your daily meals.',
      'shortDescription': 'Traditional homemade $name',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subCategoryIds': subCategoryIds,
      'images': [
        ImageConstants.productImages[_random.nextInt(ImageConstants.productImages.length)],
        ImageConstants.productImages[_random.nextInt(ImageConstants.productImages.length)]
      ],
      'variants': [
        {
          'variantId': '100g',
          'label': '100g',
          'price': (basePrice * 0.5).toInt(),
          'discountPrice': (basePrice * 0.5).toInt() - 10,
          'stock': 100,
          'isAvailable': true
        },
        {
          'variantId': '250g',
          'label': '250g',
          'price': basePrice,
          'discountPrice': basePrice - 20,
          'stock': 50,
          'isAvailable': true
        },
        {
          'variantId': '500g',
          'label': '500g',
          'price': (basePrice * 1.8).toInt(),
          'discountPrice': (basePrice * 1.8).toInt() - 40,
          'stock': 30,
          'isAvailable': true
        },
        {
          'variantId': '1kg',
          'label': '1kg',
          'price': (basePrice * 3.2).toInt(),
          'discountPrice': (basePrice * 3.2).toInt() - 100,
          'stock': 15,
          'isAvailable': true
        }
      ],
      'ingredients': ['Ingredient 1', 'Ingredient 2', 'Traditional Spices'],
      'tags': selectedTags,
      'rating': double.parse(calculatedRating.toStringAsFixed(1)),
      'totalReviews': totalReviews,
      'ratingCounts': ratingCounts,
      'ratingHighlights': ratingHighlights,
      'totalOrders': _random.nextInt(1000),
      'likes': _random.nextInt(500),
      'wishlistCount': _random.nextInt(100),
      'isFeatured': _random.nextDouble() > 0.8,
      'isTrending': _random.nextDouble() > 0.7,
      'isActive': true,
      'status': 'Live',
      'shelfLife': '${_random.nextInt(4) + 2} Months',
      'dispatchTime': '${_random.nextInt(3) + 1} Days',
      'canSellPanIndia': canSellPanIndia,
      'state': state,
      'searchKeywords': searchKeywords,
      'createdBySeeder': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // --- BANNER HELPERS ---
  static Map<String, dynamic> generateBannerData(int order, String title, String subtitle, String badge) {
    return {
      'badgeText': badge,
      'buttonText': 'Shop Now',
      'imageUrl': ImageConstants.collectionBanners[_random.nextInt(ImageConstants.collectionBanners.length)],
      'isActive': true,
      'linkUrl': '',
      'order': order,
      'subtitle': subtitle,
      'title': title,
      'createdBySeeder': true,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // --- SUBSCRIPTION HELPERS ---
  static Map<String, dynamic> generateVendorSubscriptionData(String storeId) {
    final scenarios = ['trialing', 'active', 'grace_period', 'expired'];
    final status = scenarios[_random.nextInt(scenarios.length)];
    
    DateTime now = DateTime.now();
    DateTime trialEndsAt;
    DateTime? currentPeriodEnd;

    switch (status) {
      case 'trialing':
        trialEndsAt = now.add(Duration(days: _random.nextInt(14) + 1));
        break;
      case 'active':
        trialEndsAt = now.subtract(Duration(days: _random.nextInt(30) + 10));
        currentPeriodEnd = now.add(Duration(days: _random.nextInt(30) + 1));
        break;
      case 'grace_period':
        trialEndsAt = now.subtract(Duration(days: _random.nextInt(60) + 30));
        // Grace period is within 3 days after currentPeriodEnd
        currentPeriodEnd = now.subtract(Duration(days: _random.nextInt(3)));
        break;
      case 'expired':
        trialEndsAt = now.subtract(Duration(days: _random.nextInt(90) + 60));
        currentPeriodEnd = now.subtract(Duration(days: _random.nextInt(30) + 4));
        break;
      default:
        trialEndsAt = now.add(const Duration(days: 90));
    }

    return {
      'storeId': storeId,
      'status': status,
      'trialEndsAt': trialEndsAt.toIso8601String(),
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      'createdBySeeder': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
