import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/store_update_model.dart';

class FollowingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's followed stores
  Future<List<String>> getFollowingStoreIds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).collection('followingStores').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting following store IDs: $e');
      return [];
    }
  }

  // Get full following stores metadata for UI
  Future<List<Map<String, dynamic>>> getFollowingStoresData() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).collection('followingStores').orderBy('followedAt', descending: true).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting following stores data: $e');
      return [];
    }
  }

  Future<List<StoreUpdateModel>> getFeed({
    required List<String> followingStoreIds,
    String? typeFilter,
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    if (followingStoreIds.isEmpty) return [];

    try {
      // Note: Firestore whereIn supports up to 10 items.
      // For production with >10 follows, fan-out architecture (Cloud Functions) is recommended.
      // For MVP we take the first 10.
      final storeIdsToQuery = followingStoreIds.take(10).toList();

      Query query = _firestore.collection('store_updates')
          .where('storeId', whereIn: storeIdsToQuery)
          .where('isActive', isEqualTo: true);

      if (typeFilter != null && typeFilter != 'all') {
        query = query.where('type', isEqualTo: typeFilter);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        return StoreUpdateModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting feed: $e');
      return [];
    }
  }

  // Follow a store (helper method if needed)
  // Follow a store safely with transactions/batching
  Future<void> toggleFollowStore(String storeId, {required Map<String, dynamic> storeData, required bool isCurrentlyFollowing}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userStoreRef = _firestore.collection('users').doc(user.uid).collection('followingStores').doc(storeId);
    final userRef = _firestore.collection('users').doc(user.uid);
    final storeRef = _firestore.collection('stores').doc(storeId);
    final storeFollowerRef = storeRef.collection('followers').doc(user.uid);
    final notifRef = _firestore.collection('notifications').doc();
    
    try {
      final batch = _firestore.batch();
      
      if (isCurrentlyFollowing) {
        batch.delete(userStoreRef);
        batch.delete(storeFollowerRef);
        batch.update(storeRef, {'followers': FieldValue.increment(-1)});
        batch.set(userRef, {
          'favoriteStoreIds': FieldValue.arrayRemove([storeId])
        }, SetOptions(merge: true));
      } else {
        batch.set(userStoreRef, {
          'storeId': storeId,
          'storeName': storeData['storeName'] ?? '',
          'storeLogo': storeData['storeLogo'] ?? '',
          'followedAt': FieldValue.serverTimestamp(),
          'notificationsEnabled': true,
        });
        batch.set(storeFollowerRef, {
          'userId': user.uid,
          'userName': user.displayName ?? 'Customer',
          'userProfileImage': user.photoURL ?? '',
          'followedAt': FieldValue.serverTimestamp(),
        });
        batch.update(storeRef, {'followers': FieldValue.increment(1)});
        batch.set(userRef, {
          'favoriteStoreIds': FieldValue.arrayUnion([storeId])
        }, SetOptions(merge: true));
        
        if (storeData['ownerId'] != null && storeData['ownerId'].toString().isNotEmpty) {
          batch.set(notifRef, {
            'notificationId': notifRef.id,
            'userId': storeData['ownerId'],
            'type': 'new_follower',
            'title': 'New Follower',
            'message': '${user.displayName ?? 'A customer'} started following your store',
            'referenceId': storeId,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Error toggling follow: $e');
      throw e;
    }
  }
}
