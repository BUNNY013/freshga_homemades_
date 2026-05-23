import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/store_model.dart';
import '../core/utils/search_utils.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch live suggestions from both Products and Stores (max 10 combined)
  Future<Map<String, List<dynamic>>> getLiveSuggestions(String query) async {
    final Map<String, List<dynamic>> results = {
      'products': [],
      'stores': [],
    };

    if (query.trim().isEmpty) return results;
    
    final String lowercaseQuery = query.toLowerCase().trim();

    try {
      // Run both queries concurrently
      final futures = await Future.wait([
        _firestore
            .collection('products')
            .where('searchKeywords', arrayContains: lowercaseQuery)
            .limit(5)
            .get(),
        _firestore
            .collection('stores')
            .where('searchKeywords', arrayContains: lowercaseQuery)
            .limit(5)
            .get(),
      ]);

      final productDocs = futures[0].docs;
      final storeDocs = futures[1].docs;

      results['products'] = productDocs.map((doc) => ProductModel.fromJson(doc.data(), doc.id)).toList();
      results['stores'] = storeDocs.map((doc) => StoreModel.fromJson(doc.data(), doc.id)).toList();

      return results;
    } catch (e) {
      print("Error fetching live suggestions: $e");
      return results;
    }
  }

  /// Search Products with pagination (limit 20)
  Future<List<ProductModel>> searchProducts(String query, {DocumentSnapshot? lastDocument}) async {
    if (query.trim().isEmpty) return [];
    
    final String lowercaseQuery = query.toLowerCase().trim();

    try {
      Query q = _firestore
          .collection('products')
          .where('searchKeywords', arrayContains: lowercaseQuery)
          .limit(20);

      if (lastDocument != null) {
        q = q.startAfterDocument(lastDocument);
      }

      final snapshot = await q.get();
      return snapshot.docs.map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error searching products: $e");
      return [];
    }
  }

  /// Search Stores with pagination (limit 20)
  Future<List<StoreModel>> searchStores(String query, {DocumentSnapshot? lastDocument}) async {
    if (query.trim().isEmpty) return [];
    
    final String lowercaseQuery = query.toLowerCase().trim();

    try {
      Query q = _firestore
          .collection('stores')
          .where('searchKeywords', arrayContains: lowercaseQuery)
          .limit(20);

      if (lastDocument != null) {
        q = q.startAfterDocument(lastDocument);
      }

      final snapshot = await q.get();
      return snapshot.docs.map((doc) => StoreModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print("Error searching stores: $e");
      return [];
    }
  }

  /// ONE-TIME ADMIN UTILITY:
  /// Run this once to populate 'searchKeywords' field in all existing stores.
  Future<void> populateStoreSearchKeywords() async {
    try {
      final snapshot = await _firestore.collection('stores').get();
      final batch = _firestore.batch();
      
      int count = 0;
      for (var doc in snapshot.docs) {
        final storeData = doc.data();
        final storeName = storeData['storeName'] ?? storeData['name'] ?? '';
        final tags = List<String>.from(storeData['categories'] ?? storeData['tags'] ?? []);
        
        // Combine name and tags for better searchability
        final String searchableText = "$storeName ${tags.join(' ')}";
        final List<String> searchKeywords = SearchUtils.generateSearchKeywords(searchableText);
        
        batch.update(doc.reference, {'searchKeywords': searchKeywords});
        count++;
        
        // Commit in batches of 500 to avoid Firestore limits
        if (count % 450 == 0) {
           await batch.commit();
        }
      }
      
      await batch.commit();
      print("Successfully updated $count stores with searchKeywords.");
    } catch (e) {
      print("Error populating store search keywords: $e");
    }
  }
}
