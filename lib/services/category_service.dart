import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final snapshot = await _firestore.collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Stream<List<CategoryModel>> streamActiveCategories() {
    return _firestore.collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<Map<String, dynamic>?> streamCategoryBanner() {
    return _firestore.collection('appConfig')
        .doc('categories_banner')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data()?['isActive'] == true) {
            return snapshot.data();
          }
          return null;
        });
  }

  Stream<List<SubCategoryModel>> streamSubCategories(String categoryId) {
    return _firestore.collection('sub_categories')
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SubCategoryModel.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<int> streamSubCategoryProductCount(String categoryId, String subCategoryId) {
    return _firestore.collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .where('subCategoryIds', arrayContains: subCategoryId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
