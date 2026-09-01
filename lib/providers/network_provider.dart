import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class NetworkProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  bool _isSlow = false;
  bool get isSlow => _isSlow;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _latencyTimer;

  NetworkProvider() {
    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _startLatencyCheck();
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await Connectivity().checkConnectivity();
    } catch (e) {
      result = [ConnectivityResult.none];
    }
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    bool online = !result.contains(ConnectivityResult.none);
    if (_isOnline != online) {
      _isOnline = online;
      if (online) {
        _checkLatency();
      } else {
        _isSlow = false;
      }
      notifyListeners();
    }
  }

  void _startLatencyCheck() {
    _latencyTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkLatency(),
    );
  }

  Future<void> _checkLatency() async {
    if (!_isOnline) return;
    try {
      final stopwatch = Stopwatch()..start();
      await http
          .head(Uri.parse('https://gstatic.com/generate_204'))
          .timeout(const Duration(seconds: 3));
      stopwatch.stop();
      bool slow = stopwatch.elapsedMilliseconds > 1500;
      if (_isSlow != slow) {
        _isSlow = slow;
        notifyListeners();
      }
    } catch (e) {
      if (!_isSlow) {
        _isSlow = true;
        notifyListeners();
      }
    }
  }

  /// Manually checks connectivity when the user presses 'Try Again'
  Future<void> checkConnectivity() async {
    await _initConnectivity();
    await _checkLatency();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _latencyTimer?.cancel();
    super.dispose();
  }
}
