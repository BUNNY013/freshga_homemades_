import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_update_model.dart';
import '../services/following_service.dart';

class FollowingProvider with ChangeNotifier {
  final FollowingService _service = FollowingService();

  List<String> _followingStoreIds = [];
  List<Map<String, dynamic>> _followingStoresData = [];
  bool _isLoadingIds = true;

  List<StoreUpdateModel> _feed = [];
  bool _isLoading = false;
  bool _isPaginating = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;

  String _selectedFilter =
      'all'; // all, new_launch, restock, offer, community_update

  // Getters
  List<String> get followingStoreIds => _followingStoreIds;
  List<Map<String, dynamic>> get followingStoresData => _followingStoresData;
  bool get isLoadingIds => _isLoadingIds;
  List<StoreUpdateModel> get feed => _feed;
  bool get isLoading => _isLoading;
  bool get isPaginating => _isPaginating;
  bool get hasMore => _hasMore;
  String get selectedFilter => _selectedFilter;

  // Global Check
  bool isFollowing(String storeId) => _followingStoreIds.contains(storeId);

  Future<void> initialize() async {
    _isLoadingIds = true;
    notifyListeners();

    _followingStoreIds = await _service.getFollowingStoreIds();
    _followingStoresData = await _service.getFollowingStoresData();

    _isLoadingIds = false;
    notifyListeners();

    if (_followingStoreIds.isNotEmpty) {
      await fetchFeed();
    }
  }

  Future<void> toggleFollow(
    String storeId,
    Map<String, dynamic> storeData,
  ) async {
    final currentlyFollowing = isFollowing(storeId);

    // Optimistic UI Update
    if (currentlyFollowing) {
      _followingStoreIds.remove(storeId);
      _followingStoresData.removeWhere((s) => s['storeId'] == storeId);
    } else {
      _followingStoreIds.add(storeId);
      _followingStoresData.insert(0, {
        'storeId': storeId,
        'storeName': storeData['storeName'] ?? '',
        'storeLogo': storeData['storeLogo'] ?? '',
      });
    }
    notifyListeners();

    try {
      await _service.toggleFollowStore(
        storeId,
        storeData: storeData,
        isCurrentlyFollowing: currentlyFollowing,
      );
      // Reload feed if follow state changes to keep it fresh
      fetchFeed();
    } catch (e) {
      // Revert on error
      if (currentlyFollowing) {
        _followingStoreIds.add(storeId);
        _followingStoresData.add(storeData);
      } else {
        _followingStoreIds.remove(storeId);
        _followingStoresData.removeWhere((s) => s['storeId'] == storeId);
      }
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    fetchFeed();
  }

  Future<void> fetchFeed({bool refresh = true}) async {
    if (_followingStoreIds.isEmpty) {
      _feed = [];
      _hasMore = false;
      notifyListeners();
      return;
    }

    if (refresh) {
      _isLoading = true;
      _lastDoc = null;
      _hasMore = true;
      _feed.clear();
      notifyListeners();
    } else {
      if (!_hasMore || _isPaginating) return;
      _isPaginating = true;
      notifyListeners();
    }

    try {
      final newItems = await _service.getFeed(
        followingStoreIds: _followingStoreIds,
        typeFilter: _selectedFilter,
        startAfter: _lastDoc,
        limit: 10,
      );

      if (newItems.isNotEmpty) {
        _feed.addAll(newItems);
        // The service doesn't easily expose the last doc without modifying return type,
        // so for simplicity in the provider we fetch query again or we modify service.
        // Wait, the previous implementation did the query here to get _lastDoc.
        // I will keep the raw query in the provider for pagination state to work smoothly,
        // or modify the service to return a tuple. Let's do the query here to get _lastDoc easily.
      }

      // We will do the query here to maintain _lastDoc
      Query query = FirebaseFirestore.instance
          .collection('store_updates')
          .where('storeId', whereIn: _followingStoreIds.take(10).toList())
          .where('isActive', isEqualTo: true);

      if (_selectedFilter != 'all') {
        query = query.where('type', isEqualTo: _selectedFilter);
      }

      query = query.orderBy('createdAt', descending: true).limit(10);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        final fetchedItems = snapshot.docs
            .map(
              (doc) => StoreUpdateModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        if (refresh) {
          _feed = fetchedItems;
        } else {
          // ensure no duplicates
          for (var item in fetchedItems) {
            if (!_feed.any((f) => f.updateId == item.updateId)) {
              _feed.add(item);
            }
          }
        }

        if (snapshot.docs.length < 10) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('Error fetching feed: $e');
    } finally {
      _isLoading = false;
      _isPaginating = false;
      notifyListeners();
    }
  }

  // Temporary function for testing: mock following all seeded stores
  Future<void> mockFollowStoresForTesting(List<String> storeIds) async {
    _followingStoreIds = storeIds;
    // mock some dummy data for horizontal list
    _followingStoresData = storeIds
        .map(
          (id) => {'storeId': id, 'storeName': 'Mock Store', 'storeLogo': ''},
        )
        .toList();
    await fetchFeed();
  }
}
