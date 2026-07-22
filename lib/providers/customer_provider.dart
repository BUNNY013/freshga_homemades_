import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer_model.dart';
import '../models/address_model.dart';
import '../services/customer_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class CustomerProvider with ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  CustomerModel? _currentCustomer;
  StreamSubscription<CustomerModel?>? _customerSubscription;
  bool _isLoading = true;

  CustomerModel? get currentCustomer => _currentCustomer;
  bool get isLoading => _isLoading;

  CustomerProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToCustomer(user.uid, user.phoneNumber ?? '');
        
        // Initialize push notifications exactly once per login session
        NotificationService.initialize();
      } else {
        _customerSubscription?.cancel();
        _currentCustomer = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _listenToCustomer(String uid, String phoneNumber) async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      // Ensure the document exists first
      await _customerService.getOrCreateCustomer(uid, phoneNumber);

      _customerSubscription?.cancel();
      _customerSubscription = _customerService.streamCustomer(uid).listen(
        (customer) {
          _currentCustomer = customer;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print("Customer stream error: $error");
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print("Error getting/creating customer: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLocation({
    required String city,
    required String state,
    required String country,
    required String pincode,
    required String source,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final newLoc = {
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
      };

      // Maintain up to 5 recent locations, without duplicates
      List<Map<String, dynamic>> updatedRecents = [];
      if (_currentCustomer?.recentLocations != null) {
        updatedRecents = List<Map<String, dynamic>>.from(_currentCustomer!.recentLocations!);
      }
      
      // Remove if it already exists to move it to the top
      updatedRecents.removeWhere((loc) => 
        loc['city'] == city && loc['state'] == state && loc['pincode'] == pincode
      );
      
      updatedRecents.insert(0, newLoc);
      if (updatedRecents.length > 5) {
        updatedRecents = updatedRecents.sublist(0, 5);
      }

      await _customerService.updateLocation(
        uid: user.uid,
        city: city,
        state: state,
        country: country,
        pincode: pincode,
        source: source,
        recentLocations: updatedRecents,
      );
    }
  }

  Future<void> addAddress(AddressModel address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _customerService.saveAddress(user.uid, address);
    }
  }

  Future<void> removeAddress(String addressId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _customerService.removeAddress(user.uid, addressId);
    }
  }

  Future<void> updateAddress(AddressModel address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _customerService.updateAddress(user.uid, address);
    }
  }

  @override
  void dispose() {
    _customerSubscription?.cancel();
    super.dispose();
  }
}
