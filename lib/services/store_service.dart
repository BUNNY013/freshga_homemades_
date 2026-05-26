import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<StoreModel>> getFeaturedStores() async {
    try {
      final snapshot = await _firestore.collection('stores')
          .where('verified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(10)
          .get();
      return snapshot.docs.map((doc) => StoreModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load featured stores: $e');
    }
  }

  Future<StoreModel?> getStore(String storeId) async {
    try {
      final doc = await _firestore.collection('stores').doc(storeId).get();
      if (doc.exists && doc.data() != null) {
        return StoreModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting store: $e');
      throw Exception('Failed to load store profile: $e');
    }
  }

  Future<List<ProductModel>> getAllStoreProducts(String storeId) async {
    try {
      final snapshot = await _firestore.collection('products')
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true)
          .limit(500) // Safe limit for homemade stores
          .get();
      return snapshot.docs.map((doc) => ProductModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting all store products: $e');
      return [];
    }
  }

  Future<List<StoreModel>> getStoresByIds(List<String> storeIds) async {
    if (storeIds.isEmpty) return [];
    try {
      List<StoreModel> results = [];
      for (var i = 0; i < storeIds.length; i += 10) {
        var chunk = storeIds.sublist(i, i + 10 > storeIds.length ? storeIds.length : i + 10);
        var snapshot = await _firestore.collection('stores')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        results.addAll(snapshot.docs.map((d) => StoreModel.fromJson(d.data(), d.id)).toList());
      }
      return results;
    } catch (e) {
      print('Error getting stores by ids: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSubcategoriesByIds(List<String> subCategoryIds) async {
    if (subCategoryIds.isEmpty) return [];
    try {
      // Firestore 'whereIn' limits to 10 items per query.
      // We chunk the list into groups of 10.
      List<Map<String, dynamic>> results = [];
      for (var i = 0; i < subCategoryIds.length; i += 10) {
        var chunk = subCategoryIds.sublist(i, i + 10 > subCategoryIds.length ? subCategoryIds.length : i + 10);
        var snapshot = await _firestore.collection('subcategories')
            .where('subCategoryId', whereIn: chunk)
            .get();
        results.addAll(snapshot.docs.map((d) => d.data()).toList());
      }
      return results;
    } catch (e) {
      print('Error getting subcategories: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getStoreProducts(String storeId, {DocumentSnapshot? startAfter, int limit = 20}) async {
    try {
      Query query = _firestore.collection('products')
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Error getting store products: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getFeaturedProducts(String storeId) async {
    try {
      final snapshot = await _firestore.collection('products')
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();
      return snapshot.docs.map((doc) => ProductModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting featured products: $e');
      return [];
    }
  }

  Future<void> followStore(String storeId, String userId) async {
    // In a real app, you would add the user to a subcollection or array.
    // For now we'll just increment followers.
    try {
      await _firestore.collection('stores').doc(storeId).update({
        'followers': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error following store: $e');
    }
  }

  Future<void> unfollowStore(String storeId, String userId) async {
    try {
      await _firestore.collection('stores').doc(storeId).update({
        'followers': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error unfollowing store: $e');
    }
  }
}
