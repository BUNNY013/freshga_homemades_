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
