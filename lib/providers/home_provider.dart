import 'package:flutter/foundation.dart';
import '../models/home_section_model.dart';
import '../services/home_section_service.dart';

class HomeProvider with ChangeNotifier {
  final HomeSectionService _service = HomeSectionService();
  
  List<HomeSectionModel> _sections = [];
  bool _isLoading = false;
  String? _error;

  List<HomeSectionModel> get sections => _sections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSections() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sections = await _service.getActiveSections();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
