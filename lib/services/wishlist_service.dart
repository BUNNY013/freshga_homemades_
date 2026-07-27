import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _likedProductsRef {
    final uid = _currentUserId;
    if (uid == null) return null;
    // Use 'users/{uid}/liked_products' matching followingStores rules
    return _firestore.collection('users').doc(uid).collection('liked_products');
  }

  /// One-time fetch of liked products (instant fallback for UI initialization)
  Future<List<ProductModel>> getLikedProductsOnce() async {
    final ref = _likedProductsRef;
    if (ref == null) return [];

    try {
      final snapshot = await ref.get();
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading wishlist once: $e');
      return [];
    }
  }

  /// Stream of all liked ProductModels for the current user
  Stream<List<ProductModel>> getLikedProductsStream() {
    final ref = _likedProductsRef;
    if (ref == null) {
      return Stream.value([]);
    }
    return ref.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    }).handleError((error) {
      debugPrint('Error in getLikedProductsStream: $error');
      return <ProductModel>[];
    });
  }

  /// Stream of liked product IDs for quick lookups
  Stream<Set<String>> getLikedProductIdsStream() {
    final ref = _likedProductsRef;
    if (ref == null) {
      return Stream.value({});
    }
    return ref.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    }).handleError((error) {
      debugPrint('Error in getLikedProductIdsStream: $error');
      return <String>{};
    });
  }

  /// Add a product to liked products
  Future<void> likeProduct(ProductModel product) async {
    final ref = _likedProductsRef;
    if (ref == null) return;

    try {
      // Build an explicitly typed Map<String, dynamic> compatible with Android MethodChannel
      final data = <String, dynamic>{
        'storeId': product.storeId,
        'storeName': product.storeName,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'originalPrice': product.originalPrice,
        'imageUrl': product.imageUrl,
        'images': List<String>.from(product.images),
        'isTrending': product.isTrending,
        'rating': product.rating,
        'totalReviews': product.reviewsCount,
        'categoryId': product.categoryId,
        'categoryName': product.categoryName,
        'subCategoryIds': List<String>.from(product.subCategoryIds),
        'tags': List<String>.from(product.tags),
        'searchKeywords': List<String>.from(product.searchKeywords),
        'ingredients': List<String>.from(product.ingredients),
        'variants': product.variants.map((v) => <String, dynamic>{
          'id': v.id,
          'label': v.label,
          'price': v.price,
          'discountPrice': v.discountPrice,
          'stock': v.stock,
          'inStock': v.inStock,
          'isArchived': v.isArchived,
          'manageStock': v.manageStock,
          'weightGrams': v.weightGrams,
          'lengthCm': v.lengthCm,
          'widthCm': v.widthCm,
          'heightCm': v.heightCm,
        }).toList(),
        'ratingCounts': product.ratingCounts.map((k, v) => MapEntry(k.toString(), v)),
        'ratingHighlights': product.ratingHighlights.map((k, v) => MapEntry(k.toString(), v)),
        'shelfLife': product.shelfLife,
        'dispatchTime': product.dispatchTime,
        'isStoreVerified': product.isStoreVerified,
        'status': product.status,
        'state': product.state,
        'canSellPanIndia': product.canSellPanIndia,
        'likedAt': FieldValue.serverTimestamp(),
      };

      await ref.doc(product.id).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error likeProduct ($e)');
      rethrow;
    }
  }

  /// Remove a product from liked products
  Future<void> unlikeProduct(String productId) async {
    final ref = _likedProductsRef;
    if (ref == null) return;

    try {
      await ref.doc(productId).delete();
    } catch (e) {
      debugPrint('Error unlikeProduct ($e)');
      rethrow;
    }
  }

  /// Toggle liked status
  Future<bool> toggleLike(ProductModel product, bool currentlyLiked) async {
    if (currentlyLiked) {
      await unlikeProduct(product.id);
      return false;
    } else {
      await likeProduct(product);
      return true;
    }
  }

  /// Check if a specific product is liked
  Future<bool> isLiked(String productId) async {
    final ref = _likedProductsRef;
    if (ref == null) return false;

    try {
      final doc = await ref.doc(productId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
