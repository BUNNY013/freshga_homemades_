import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';

class BannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<BannerModel>> getActiveBanners() async {
    try {
      final snapshot = await _firestore.collection('banners')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();
      return snapshot.docs.map((doc) => BannerModel.fromJson(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load banners: $e');
    }
  }
}
