import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/store_model.dart';
import '../core/utils/search_utils.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch live suggestions from both Products and Stores (max 10 combined)
  Future<Map<String, List<dynamic>>> getLiveSuggestions(
    String query, {
    bool isStoreSearch = false,
  }) async {
    final Map<String, List<dynamic>> results = {'products': [], 'stores': []};

    if (query.trim().isEmpty) return results;

    final String lowercaseQuery = query.toLowerCase().trim();

    try {
      List<Future<QuerySnapshot>> tasks = [];

      if (!isStoreSearch) {
        tasks.add(
          _firestore
              .collection('products')
              .where('isActive', isEqualTo: true)
              .where('searchKeywords', arrayContains: lowercaseQuery)
              .limit(5)
              .get(),
        );
      }

      // For store search, if it's explicitly a store search (@handle),
      // we check storeSlug prefix directly to ensure instant matches even without keywords.
      Query storeQuery;
      if (isStoreSearch) {
        storeQuery = _firestore
            .collection('stores')
            .where('storeSlug', isGreaterThanOrEqualTo: lowercaseQuery)
            .where('storeSlug', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
            .limit(10);
      } else {
        storeQuery = _firestore
            .collection('stores')
            .where('searchKeywords', arrayContains: lowercaseQuery)
            .limit(5);
      }

      tasks.add(storeQuery.get());

      final futures = await Future.wait(tasks);

      if (isStoreSearch) {
        final storeDocs = futures[0].docs;
        results['stores'] = storeDocs
            .map(
              (doc) => StoreModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();
      } else {
        final productDocs = futures[0].docs;
        final storeDocs = futures[1].docs;
        results['products'] = productDocs
            .map(
              (doc) => ProductModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();
        results['stores'] = storeDocs
            .map(
              (doc) => StoreModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();
      }

      return results;
    } catch (e) {
      print("Error fetching live suggestions: $e");
      return results;
    }
  }

  /// Search Products with pagination (limit 20)
  Future<List<ProductModel>> searchProducts(
    String query, {
    DocumentSnapshot? lastDocument,
  }) async {
    if (query.trim().isEmpty) return [];

    final String lowercaseQuery = query.toLowerCase().trim();

    try {
      Query q = _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .where('searchKeywords', arrayContains: lowercaseQuery)
          .limit(20);

      if (lastDocument != null) {
        q = q.startAfterDocument(lastDocument);
      }

      final snapshot = await q.get();
      return snapshot.docs
          .map(
            (doc) => ProductModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      print("Error searching products: $e");
      return [];
    }
  }

  /// Search Stores with pagination (limit 20)
  Future<List<StoreModel>> searchStores(
    String query, {
    DocumentSnapshot? lastDocument,
    bool isStoreSearch = false,
  }) async {
    if (query.trim().isEmpty) return [];

    final String lowercaseQuery = query.toLowerCase().trim();

    try {
      Query q;
      if (isStoreSearch) {
        q = _firestore
            .collection('stores')
            .where('storeSlug', isGreaterThanOrEqualTo: lowercaseQuery)
            .where('storeSlug', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
            .limit(20);
      } else {
        q = _firestore
            .collection('stores')
            .where('searchKeywords', arrayContains: lowercaseQuery)
            .limit(20);
      }

      if (lastDocument != null) {
        q = q.startAfterDocument(lastDocument);
      }

      final snapshot = await q.get();
      return snapshot.docs
          .map(
            (doc) =>
                StoreModel.fromJson(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print("Error searching stores: $e");
      return [];
    }
  }

  /// Fetch specific stores by their IDs (useful for aggregating stores from product results)
  Future<List<StoreModel>> getStoresByIds(List<String> storeIds) async {
    if (storeIds.isEmpty) return [];

    try {
      // If > 10, chunk the requests because whereIn has a limit of 10
      List<StoreModel> stores = [];
      for (var i = 0; i < storeIds.length; i += 10) {
        final chunk = storeIds.sublist(
          i,
          i + 10 > storeIds.length ? storeIds.length : i + 10,
        );
        final snapshot = await _firestore
            .collection('stores')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        stores.addAll(
          snapshot.docs.map((doc) => StoreModel.fromJson(doc.data(), doc.id)),
        );
      }
      return stores;
    } catch (e) {
      print("Error fetching stores by ids: $e");
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
        final storeSlug = storeData['storeSlug'] ?? '';
        final tags = List<String>.from(
          storeData['categories'] ?? storeData['tags'] ?? [],
        );

        // Combine name, slug, and tags for better searchability
        final String searchableText = "$storeName $storeSlug ${tags.join(' ')}";
        final List<String> searchKeywords = SearchUtils.generateSearchKeywords(
          searchableText,
        );

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
