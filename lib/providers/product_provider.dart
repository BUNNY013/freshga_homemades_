import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _service = ProductService();
  
  List<ProductModel> _trendingProducts = [];
  bool _isLoading = false;

  List<ProductModel> get trendingProducts => _trendingProducts;
  bool get isLoading => _isLoading;

  Future<void> loadTrendingProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _trendingProducts = await _service.getTrendingProducts();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
