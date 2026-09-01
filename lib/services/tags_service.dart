import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tag_model.dart';

class TagsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<TagModel>> getActiveTags() async {
    try {
      final snapshot = await _firestore
          .collection('tags')
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TagModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tags: $e');
    }
  }

  Stream<List<TagModel>> streamTrendingTags() {
    return _firestore
        .collection('tags')
        .where('isActive', isEqualTo: true)
        .where('isTrending', isEqualTo: true)
        .orderBy('priority', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TagModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }
}
