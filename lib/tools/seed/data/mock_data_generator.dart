import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_constants.dart';

class MockDataGenerator {
  static final Random _random = Random();

  static const List<String> storePrefixes = ['The Heritage', 'Organic', 'Grandma\'s', 'Amma\'s', 'NatureNest', 'Village Spice', 'Traditional', 'Pure Harvest', 'Rustic', 'Golden Harvest'];
  static const List<String> storeSuffixes = ['Kitchen', 'Roots', 'Secrets', 'Pickles', 'Foods', 'House', 'Bowl', 'Recipes', 'Farm', 'Pantry'];

  static const List<String> productPrefixes = ['Spicy', 'Wild Forest', 'Garlic', 'Millet', 'Traditional Ghee', 'Homemade', 'Dry Fruit', 'Masala', 'Premium', 'Authentic'];
  static const List<String> productBases = ['Mango Pickle', 'Honey', 'Chutney Powder', 'Laddu', 'Cookies', 'Amla Pickle', 'Murukku', 'Gongura Pickle', 'Peanuts', 'Mixture'];

  static const List<String> tags = ['spicy', 'traditional', 'homemade', 'organic', 'fresh', 'healthy', 'sweet', 'savory', 'authentic', 'premium'];

  // --- STORE HELPERS ---
  static String generateStoreName() {
    return '${storePrefixes[_random.nextInt(storePrefixes.length)]} ${storeSuffixes[_random.nextInt(storeSuffixes.length)]}';
  }

  static String generateSlug(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-').replaceAll(RegExp(r'-+'), '-');
  }

  static Map<String, dynamic> generateStoreData(String storeId, String ownerId) {
    final name = generateStoreName();
    final isVerified = _random.nextBool();
    
    return {
      'storeId': storeId,
      'ownerId': ownerId,
      'storeName': name,
      'storeSlug': generateSlug(name),
      'description': 'Handcrafted with love. Traditional recipes passed down through generations.',
      'logo': ImageConstants.storeLogos[_random.nextInt(ImageConstants.storeLogos.length)],
      'banner': ImageConstants.storeBanners[_random.nextInt(ImageConstants.storeBanners.length)],
      'instagramLink': 'https://instagram.com/mock',
      'youtubeLink': '',
      'facebookLink': '',
      'categories': ['Pickles', 'Snacks'],
      'followers': _random.nextInt(5000),
      'likesCount': _random.nextInt(10000),
      'productsCount': _random.nextInt(50) + 5,
      'rating': double.parse((3.5 + _random.nextDouble() * 1.5).toStringAsFixed(1)),
      'totalReviews': _random.nextInt(500),
      'totalOrders': _random.nextInt(2000),
      'verified': isVerified,
      'isFeatured': isVerified && _random.nextDouble() > 0.7,
      'isActive': true,
      'dispatchTime': '${_random.nextInt(2) + 1}-${_random.nextInt(3) + 3} Days',
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
    required String subCategoryId,
  }) {
    final name = '${productPrefixes[_random.nextInt(productPrefixes.length)]} ${productBases[_random.nextInt(productBases.length)]}';
    final basePrice = 150 + _random.nextInt(400);

    return {
      'productId': productId,
      'storeId': storeId,
      'storeName': storeName,
      'name': name,
      'slug': generateSlug(name) + '-$productId',
      'description': 'Authentic homemade $name made with premium ingredients and no preservatives. A perfect addition to your daily meals.',
      'shortDescription': 'Traditional homemade $name',
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'images': [
        ImageConstants.productImages[_random.nextInt(ImageConstants.productImages.length)],
        ImageConstants.productImages[_random.nextInt(ImageConstants.productImages.length)]
      ],
      'variants': [
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
          'price': basePrice * 1.8,
          'discountPrice': (basePrice * 1.8) - 40,
          'stock': 30,
          'isAvailable': true
        }
      ],
      'ingredients': ['Ingredient 1', 'Ingredient 2', 'Traditional Spices'],
      'tags': [tags[_random.nextInt(tags.length)], tags[_random.nextInt(tags.length)]],
      'rating': double.parse((3.8 + _random.nextDouble() * 1.2).toStringAsFixed(1)),
      'totalReviews': _random.nextInt(200),
      'totalOrders': _random.nextInt(1000),
      'likes': _random.nextInt(500),
      'wishlistCount': _random.nextInt(100),
      'isFeatured': _random.nextDouble() > 0.8,
      'isTrending': _random.nextDouble() > 0.7,
      'isActive': true,
      'searchKeywords': name.toLowerCase().split(' ')..add(categoryId.toLowerCase()),
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
}
