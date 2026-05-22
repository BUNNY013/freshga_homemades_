import 'package:flutter/foundation.dart';
import '../models/store_model.dart';
import '../services/store_service.dart';

class StoreProvider with ChangeNotifier {
  final StoreService _service = StoreService();
  
  List<StoreModel> _stores = [];
  bool _isLoading = false;

  List<StoreModel> get stores => _stores;
  bool get isLoading => _isLoading;

  Future<void> loadFeaturedStores() async {
    _isLoading = true;
    notifyListeners();
    try {
      _stores = await _service.getFeaturedStores();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
