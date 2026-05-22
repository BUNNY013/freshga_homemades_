import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final snapshot = await _firestore.collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();
      return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }
}
