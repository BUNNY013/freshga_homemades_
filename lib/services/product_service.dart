import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ProductModel>> getTrendingProducts() async {
    try {
      final snapshot = await _firestore.collection('products')
          .where('isTrending', isEqualTo: true)
          .limit(10)
          .get();
      return snapshot.docs.map((doc) => ProductModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load trending products: $e');
    }
  }
  
  Future<List<ProductModel>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final snapshot = await _firestore.collection('products')
          .where(FieldPath.documentId, whereIn: ids.take(10).toList())
          .get();
      return snapshot.docs.map((doc) => ProductModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
}
