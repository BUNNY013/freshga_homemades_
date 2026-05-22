import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_section_model.dart';

class HomeSectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<HomeSectionModel>> getActiveSections() async {
    try {
      final snapshot = await _firestore.collection('home_sections')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();
      return snapshot.docs.map((doc) => HomeSectionModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load home sections: $e');
    }
  }
}
