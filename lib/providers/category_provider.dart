import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _service = CategoryService();
  
  List<CategoryModel> _categories = [];
  Map<String, dynamic>? _bannerData;
  bool _isLoading = false;

  StreamSubscription<List<CategoryModel>>? _categoriesSub;
  StreamSubscription<Map<String, dynamic>?>? _bannerSub;

  List<CategoryModel> get categories => _categories;
  Map<String, dynamic>? get bannerData => _bannerData;
  bool get isLoading => _isLoading;

  CategoryProvider() {
    initStreams();
  }

  void initStreams() {
    _isLoading = true;
    notifyListeners();

    _categoriesSub?.cancel();
    _categoriesSub = _service.streamActiveCategories().listen((cats) {
      _categories = cats;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error streaming categories: $e");
      _isLoading = false;
      notifyListeners();
    });

    _bannerSub?.cancel();
    _bannerSub = _service.streamCategoryBanner().listen((banner) {
      _bannerData = banner;
      notifyListeners();
    });
  }

  Future<void> loadCategories() async {
    // Kept for backward compatibility if it's explicitly called somewhere
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    _bannerSub?.cancel();
    super.dispose();
  }
}
