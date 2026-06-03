import 'package:flutter/foundation.dart';
import '../models/banner_model.dart';
import '../services/banner_service.dart';

class BannerProvider with ChangeNotifier {
  final BannerService _service = BannerService();
  
  List<BannerModel> _banners = [];
  bool _isLoading = false;

  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;

  Future<void> loadBanners() async {
    if (_banners.isNotEmpty) return; // Prevent redundant reads

    _isLoading = true;
    notifyListeners();
    try {
      _banners = await _service.getActiveBanners();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
