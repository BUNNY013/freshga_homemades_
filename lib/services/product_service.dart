import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ProductModel>> getTrendingProducts() async {
    try {
      final snapshot = await _firestore.collection('products')
          .where('isTrending', isEqualTo: true)
          .limit(10)
          .get();
      return snapshot.docs.map((doc) => ProductModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load trending products: $e');
    }
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

  Future<List<ProductModel>> getSimilarProducts(ProductModel product) async {
    try {
      // 1. Same category
      // 2. Overlapping subCategoryIds
      // We will query by categoryId and then sort/filter in memory for overlapping subcategories,
      // as Firestore cannot efficiently do "where in array" and "sort by overlap".
      final snapshot = await _firestore.collection('products')
          .where('categoryId', isEqualTo: product.categoryId)
          .where(FieldPath.documentId, isNotEqualTo: product.id)
          .limit(20) // Fetch some to sort in memory
          .get();

      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
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

  Future<List<ProductModel>> getSuggestedProducts(ProductModel product) async {
    try {
      // Suggested products: high ratings, best selling, or related tags.
      // We will query for high rating products, then rank them by tag similarity.
      final snapshot = await _firestore.collection('products')
          .where('rating', isGreaterThanOrEqualTo: 4.5)
          .where(FieldPath.documentId, isNotEqualTo: product.id)
          .limit(20)
          .get();

      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
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
