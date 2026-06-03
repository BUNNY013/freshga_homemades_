import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_section_model.dart';

class HomeSectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getActiveSections({DocumentSnapshot? startAfter, int limit = 3}) async {
    try {
      Query query = _firestore.collection('home_sections')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      
      final sections = snapshot.docs.map((doc) => HomeSectionModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return {
        'sections': sections,
        'lastDoc': lastDoc,
      };
    } catch (e) {
      throw Exception('Failed to load home sections: $e');
    }
  }
}
