import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';

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
      throw Exception('Failed to load stores: $e');
    }
  }
}
