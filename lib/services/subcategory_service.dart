import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subcategory_model.dart';

class SubCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SubCategoryModel>> getSubCategories(String categoryId) async {
    try {
      final snapshot = await _firestore.collection('sub_categories')
          .where('categoryId', isEqualTo: categoryId)
          .where('status', isEqualTo: 'active')
          .orderBy('displayIndex')
          .get();
      return snapshot.docs.map((doc) => SubCategoryModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load subcategories: $e');
    }
  }

  Stream<List<SubCategoryModel>> streamSubCategories(String categoryId) {
    return _firestore.collection('sub_categories')
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'active')
        .orderBy('displayIndex')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SubCategoryModel.fromJson(doc.data(), doc.id)).toList());
  }
}
