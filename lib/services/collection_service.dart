import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_model.dart';

class CollectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CollectionModel>> getCollections() async {
    try {
      final snapshot = await _firestore.collection('collections')
          .limit(5)
          .get();
      return snapshot.docs.map((doc) => CollectionModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load collections: $e');
    }
  }
}
