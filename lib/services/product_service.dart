import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ProductModel>> getTrendingProducts({String? customerState}) async {
    try {
      Query query = _firestore.collection('products')
          .where('isActive', isEqualTo: true)
          .where('isTrending', isEqualTo: true);

      if (customerState != null && customerState.isNotEmpty) {
        query = query.where(Filter.or(
          Filter('canSellPanIndia', isEqualTo: true),
          Filter('state', isEqualTo: customerState)
        ));
      }

      final snapshot = await query.limit(10).get();
      return snapshot.docs.map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load trending products: $e');
    }
  }

  Future<List<ProductModel>> getRandomDiscoveryProducts({int limit = 50, String? customerState}) async {
    try {
      Query query = _firestore.collection('products')
          .where('isActive', isEqualTo: true);
          
      if (customerState != null && customerState.isNotEmpty) {
        query = query.where(Filter.or(
          Filter('canSellPanIndia', isEqualTo: true),
          Filter('state', isEqualTo: customerState)
        ));
      }

      final snapshot = await query.limit(limit).get();
          
      final products = snapshot.docs.map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
      
      // Shuffle the list to make the feed dynamic and different every time
      products.shuffle();
      
      return products;
    } catch (e) {
      print('Error getting random discovery products: $e');
      return [];
    }
  }
  
  Stream<List<ProductModel>> streamProductsByCategory(String categoryId, {String? customerState}) {
    Query query = _firestore.collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true);

    if (customerState != null && customerState.isNotEmpty) {
      query = query.where(Filter.or(
        Filter('canSellPanIndia', isEqualTo: true),
        Filter('state', isEqualTo: customerState)
      ));
    }

    return query
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Future<ProductModel?> getProduct(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return ProductModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  Future<List<ProductModel>> getSimilarProducts(ProductModel product, {String? customerState}) async {
    try {
      Query query = _firestore.collection('products')
          .where('categoryId', isEqualTo: product.categoryId)
          .where('isActive', isEqualTo: true)
          .where(FieldPath.documentId, isNotEqualTo: product.id);

      if (customerState != null && customerState.isNotEmpty) {
        query = query.where(Filter.or(
          Filter('canSellPanIndia', isEqualTo: true),
          Filter('state', isEqualTo: customerState)
        ));
      }

      final snapshot = await query.limit(20).get();

      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Sort by overlapping subcategories, then by rating/bestselling
      products.sort((a, b) {
        int aOverlap = a.subCategoryIds.where((sub) => product.subCategoryIds.contains(sub)).length;
        int bOverlap = b.subCategoryIds.where((sub) => product.subCategoryIds.contains(sub)).length;
        if (aOverlap != bOverlap) {
          return bOverlap.compareTo(aOverlap); // Descending overlap
        }
        // If same overlap, check tags overlap
        int aTagsOverlap = a.tags.where((tag) => product.tags.contains(tag)).length;
        int bTagsOverlap = b.tags.where((tag) => product.tags.contains(tag)).length;
        if (aTagsOverlap != bTagsOverlap) {
          return bTagsOverlap.compareTo(aTagsOverlap);
        }
        // Finally, sort by rating
        return b.rating.compareTo(a.rating);
      });

      return products.take(10).toList(); // Return top 10 similar
    } catch (e) {
      print('Error getting similar products: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getSuggestedProducts(ProductModel product, {String? customerState}) async {
    try {
      Query query = _firestore.collection('products')
          .where('isActive', isEqualTo: true)
          .where('rating', isGreaterThanOrEqualTo: 4.5)
          .where(FieldPath.documentId, isNotEqualTo: product.id);

      if (customerState != null && customerState.isNotEmpty) {
        query = query.where(Filter.or(
          Filter('canSellPanIndia', isEqualTo: true),
          Filter('state', isEqualTo: customerState)
        ));
      }

      final snapshot = await query.limit(20).get();

      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Sort by tag overlap
      products.sort((a, b) {
        int aTagsOverlap = a.tags.where((tag) => product.tags.contains(tag)).length;
        int bTagsOverlap = b.tags.where((tag) => product.tags.contains(tag)).length;
        if (aTagsOverlap != bTagsOverlap) {
          return bTagsOverlap.compareTo(aTagsOverlap);
        }
        return b.rating.compareTo(a.rating);
      });

      return products.take(10).toList();
    } catch (e) {
      print('Error getting suggested products: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getStoreProducts(String storeId, {String? excludeProductId, int limit = 10}) async {
    try {
      final snapshot = await _firestore.collection('products')
          .where('storeId', isEqualTo: storeId)
          .where('status', whereIn: ['Live', 'Live + Draft Changes', 'Live + Update Pending', 'Unavailable'])
          .limit(limit + 1) // +1 in case we need to filter out the excluded one
          .get();

      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (excludeProductId != null) {
        products.removeWhere((p) => p.id == excludeProductId);
      }

      return products.take(limit).toList();
    } catch (e) {
      print('Error getting store products: $e');
      return [];
    }
  }

  Future<void> addToCart(String productId, int quantity, String variant) async {
    // Implement cart logic. Typically involves writing to a user's subcollection.
    // For now, this just simulates an API call.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> toggleWishlist(String productId) async {
    // Implement wishlist logic.
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
