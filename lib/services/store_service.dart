import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<StoreModel>> getFeaturedStores() async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .where('verified', isEqualTo: true)
          .where('status', isEqualTo: 'Active')
          .orderBy('rating', descending: true)
          .limit(20) // Fetch more to account for filtered ones
          .get();
      final stores = snapshot.docs
          .map(
            (doc) =>
                StoreModel.fromJson(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
      return await _filterActiveStores(stores, limit: 10);
    } catch (e) {
      throw Exception('Failed to load featured stores: $e');
    }
  }

  Future<List<StoreModel>> getLocalStores(String city, String state) async {
    try {
      // Primary query: Match exactly by City
      Query query = _firestore
          .collection('stores')
          .where('status', isEqualTo: 'Active')
          .where('city', isEqualTo: city);

      final snapshot = await query.limit(20).get();

      List<StoreModel> stores = snapshot.docs
          .map(
            (doc) =>
                StoreModel.fromJson(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Fallback: If less than 3 stores in city, broaden to State
      if (stores.length < 3) {
        final stateQuery = await _firestore
            .collection('stores')
            .where('status', isEqualTo: 'Active')
            .where('state', isEqualTo: state)
            .limit(10)
            .get();

        final stateStores = stateQuery.docs
            .map(
              (doc) => StoreModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        // Merge without duplicates
        for (var store in stateStores) {
          if (!stores.any((s) => s.id == store.id)) {
            stores.add(store);
          }
        }
      }
      return await _filterActiveStores(stores, limit: 10);
    } catch (e) {
      print('Error loading local stores: $e');
      return [];
    }
  }

  Future<List<StoreModel>> getNewStores() async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .where('status', isEqualTo: 'Active')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      final stores = snapshot.docs
          .map(
            (doc) =>
                StoreModel.fromJson(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
      return await _filterActiveStores(stores, limit: 10);
    } catch (e) {
      print('Error loading new stores: $e');
      return [];
    }
  }

  Future<StoreModel?> getStore(String storeId) async {
    try {
      final doc = await _firestore.collection('stores').doc(storeId).get();
      if (doc.exists && doc.data() != null) {
        final store = StoreModel.fromJson(doc.data()!, doc.id);
        
        final subDoc = await _firestore.collection('store_subscriptions').doc(storeId).get();
        if (subDoc.exists) {
          final data = subDoc.data()!;
          final status = data['status'] ?? 'expired';
          final trialEndsAtStr = data['trialEndsAt'];
          final currentPeriodEndStr = data['currentPeriodEnd'];

          final trialEndsAt = trialEndsAtStr != null
              ? (trialEndsAtStr is Timestamp
                    ? trialEndsAtStr.toDate()
                    : DateTime.parse(trialEndsAtStr.toString()))
              : DateTime.now().subtract(const Duration(days: 1));
          final currentPeriodEnd = currentPeriodEndStr != null
              ? (currentPeriodEndStr is Timestamp
                    ? currentPeriodEndStr.toDate()
                    : DateTime.parse(currentPeriodEndStr.toString()))
              : null;

          final isTrialActive =
              status == 'trialing' && DateTime.now().isBefore(trialEndsAt);
          final isPaidActive =
              status == 'active' &&
              currentPeriodEnd != null &&
              DateTime.now().isBefore(currentPeriodEnd);

          bool isInGracePeriod = false;
          if (currentPeriodEnd != null) {
            final graceEndsAt = currentPeriodEnd.add(const Duration(days: 3));
            isInGracePeriod =
                DateTime.now().isAfter(currentPeriodEnd) &&
                DateTime.now().isBefore(graceEndsAt);
          }
          store.hasValidSubscription = isTrialActive || isPaidActive || isInGracePeriod;
        } else {
          store.hasValidSubscription = false;
        }
        
        return store;
      }
      return null;
    } catch (e) {
      print('Error getting store: $e');
      throw Exception('Failed to load store profile: $e');
    }
  }

  Future<List<ProductModel>> getAllStoreProducts(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('storeId', isEqualTo: storeId)
          .limit(500) // Safe limit for homemade stores
          .get();

      final allProducts = snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();

      // Filter locally to avoid requiring composite indexes
      final allowedStatuses = [
        'Live',
        'Live + Draft Changes',
        'Live + Update Pending',
        'Unavailable',
      ];
      return allProducts
          .where((p) => allowedStatuses.contains(p.status))
          .toList();
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
        var chunk = storeIds.sublist(
          i,
          i + 10 > storeIds.length ? storeIds.length : i + 10,
        );
        var snapshot = await _firestore
            .collection('stores')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        results.addAll(
          snapshot.docs
              .map(
                (d) =>
                    StoreModel.fromJson(d.data() as Map<String, dynamic>, d.id),
              )
              .toList(),
        );
      }
      return results;
    } catch (e) {
      print('Error getting stores by ids: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSubcategoriesByIds(
    List<String> subCategoryIds,
  ) async {
    if (subCategoryIds.isEmpty) return [];
    try {
      // Firestore 'whereIn' limits to 10 items per query.
      // We chunk the list into groups of 10.
      List<Map<String, dynamic>> results = [];
      for (var i = 0; i < subCategoryIds.length; i += 10) {
        var chunk = subCategoryIds.sublist(
          i,
          i + 10 > subCategoryIds.length ? subCategoryIds.length : i + 10,
        );
        var snapshot = await _firestore
            .collection('sub_categories')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        // Since we are querying by documentId, ensure the subCategoryId is correctly mapped
        results.addAll(
          snapshot.docs.map((d) {
            final data = d.data();
            data['subCategoryId'] = d.id;
            return data;
          }).toList(),
        );
      }
      return results;
    } catch (e) {
      print('Error getting subcategories: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getStoreProducts(
    String storeId, {
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('products')
          .where('storeId', isEqualTo: storeId)
          .where(
            'status',
            whereIn: [
              'Live',
              'Live + Draft Changes',
              'Live + Update Pending',
              'Unavailable',
            ],
          )
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => ProductModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting store products: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getFeaturedProducts(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('storeId', isEqualTo: storeId)
          .where(
            'status',
            whereIn: [
              'Live',
              'Live + Draft Changes',
              'Live + Update Pending',
              'Unavailable',
            ],
          )
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
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

  // --- Subscription Helper ---
  Future<bool> isStoreActive(String storeId) async {
    try {
      final subDoc = await _firestore
          .collection('store_subscriptions')
          .doc(storeId)
          .get();
      if (!subDoc.exists) return false;

      final data = subDoc.data()!;
      final status = data['status'] ?? 'expired';
      final trialEndsAtStr = data['trialEndsAt'];
      final currentPeriodEndStr = data['currentPeriodEnd'];

      final trialEndsAt = trialEndsAtStr != null
          ? (trialEndsAtStr is Timestamp
                ? trialEndsAtStr.toDate()
                : DateTime.parse(trialEndsAtStr.toString()))
          : DateTime.now().subtract(const Duration(days: 1));
      final currentPeriodEnd = currentPeriodEndStr != null
          ? (currentPeriodEndStr is Timestamp
                ? currentPeriodEndStr.toDate()
                : DateTime.parse(currentPeriodEndStr.toString()))
          : null;

      final isTrialActive =
          status == 'trialing' && DateTime.now().isBefore(trialEndsAt);
      final isPaidActive =
          status == 'active' &&
          currentPeriodEnd != null &&
          DateTime.now().isBefore(currentPeriodEnd);

      bool isInGracePeriod = false;
      if (currentPeriodEnd != null) {
        final graceEndsAt = currentPeriodEnd.add(const Duration(days: 3));
        isInGracePeriod =
            DateTime.now().isAfter(currentPeriodEnd) &&
            DateTime.now().isBefore(graceEndsAt);
      }

      return isTrialActive || isPaidActive || isInGracePeriod;
    } catch (e) {
      print("Error checking store active status: $e");
      return false; // Fallback to offline on error for safety
    }
  }

  Future<List<StoreModel>> _filterActiveStores(
    List<StoreModel> stores, {
    int limit = 10,
  }) async {
    if (stores.isEmpty) return [];
    List<StoreModel> activeStores = [];

    // We check each store's subscription document.
    // If it's expired/missing (and no trial), we filter it out.
    for (var store in stores) {
      try {
        final subDoc = await _firestore
            .collection('store_subscriptions')
            .doc(store.id)
            .get();
        // We always keep the store if it's fetched, but we flag if subscription is invalid
        if (!subDoc.exists) {
          store.hasValidSubscription = false;
        } else {
          final data = subDoc.data()!;
          final status = data['status'] ?? 'expired';
          final trialEndsAtStr = data['trialEndsAt'];
          final currentPeriodEndStr = data['currentPeriodEnd'];

          final trialEndsAt = trialEndsAtStr != null
              ? (trialEndsAtStr is Timestamp
                    ? trialEndsAtStr.toDate()
                    : DateTime.parse(trialEndsAtStr.toString()))
              : DateTime.now().subtract(const Duration(days: 1));
          final currentPeriodEnd = currentPeriodEndStr != null
              ? (currentPeriodEndStr is Timestamp
                    ? currentPeriodEndStr.toDate()
                    : DateTime.parse(currentPeriodEndStr.toString()))
              : null;

          final isTrialActive =
              status == 'trialing' && DateTime.now().isBefore(trialEndsAt);
          final isPaidActive =
              status == 'active' &&
              currentPeriodEnd != null &&
              DateTime.now().isBefore(currentPeriodEnd);

          bool isInGracePeriod = false;
          if (currentPeriodEnd != null) {
            final graceEndsAt = currentPeriodEnd.add(const Duration(days: 3));
            isInGracePeriod =
                DateTime.now().isAfter(currentPeriodEnd) &&
                DateTime.now().isBefore(graceEndsAt);
          }

          store.hasValidSubscription = isTrialActive || isPaidActive || isInGracePeriod;
        }

        activeStores.add(store);
        if (activeStores.length >= limit) break; // Reached desired limit
      } catch (e) {
        print("Error checking subscription for ${store.id}: $e");
      }
    }

    return activeStores;
  }
}
