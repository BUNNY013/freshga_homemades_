import 'package:flutter/foundation.dart';
import '../models/collection_model.dart';
import '../services/collection_service.dart';

class CollectionProvider with ChangeNotifier {
  final CollectionService _service = CollectionService();

  List<CollectionModel> _collections = [];
  bool _isLoading = false;

  List<CollectionModel> get collections => _collections;
  bool get isLoading => _isLoading;

  Future<void> loadCollections() async {
    if (_collections.isNotEmpty) return; // Prevent redundant reads

    _isLoading = true;
    notifyListeners();
    try {
      _collections = await _service.getCollections();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
