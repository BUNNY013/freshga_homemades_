import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_section_model.dart';
import '../services/home_section_service.dart';

class HomeProvider with ChangeNotifier {
  final HomeSectionService _service = HomeSectionService();

  List<HomeSectionModel> _sections = [];
  bool _isLoading = false;
  String? _error;

  // Pagination State
  bool _isPaginating = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;

  List<HomeSectionModel> get sections => _sections;
  bool get isLoading => _isLoading;
  bool get isPaginating => _isPaginating;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadSections({bool refresh = false}) async {
    if (refresh) {
      _lastDoc = null;
      _hasMore = true;
      _sections.clear();
    } else if (_sections.isNotEmpty) {
      return; // Already loaded
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getActiveSections(
        limit: 10,
      ); // Load first 10 sections
      _sections = List<HomeSectionModel>.from(result['sections']);
      _lastDoc = result['lastDoc'];

      if (_sections.length < 10) {
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSections() async {
    if (_isPaginating || !_hasMore) return;

    _isPaginating = true;
    notifyListeners();

    try {
      final result = await _service.getActiveSections(
        startAfter: _lastDoc,
        limit: 3, // Load 3 more sections per page
      );

      final newSections = List<HomeSectionModel>.from(result['sections']);
      if (newSections.isNotEmpty) {
        _sections.addAll(newSections);
        _lastDoc = result['lastDoc'];
      }

      if (newSections.length < 3) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint("Error paginating home sections: $e");
    } finally {
      _isPaginating = false;
      notifyListeners();
    }
  }
}
