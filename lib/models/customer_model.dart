import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_model.dart';

class CustomerModel {
  final String uid;
  final String phoneNumber;
  final Map<String, dynamic>? selectedLocation;
  final List<Map<String, dynamic>>? recentLocations;
  final String? locationSource; // 'gps', 'manual', 'checkout_address'
  final DateTime? locationUpdatedAt;
  final DateTime createdAt;
  final String? fcmToken;
  final List<AddressModel>? savedAddresses;

  CustomerModel({
    required this.uid,
    required this.phoneNumber,
    this.selectedLocation,
    this.recentLocations,
    this.locationSource,
    this.locationUpdatedAt,
    required this.createdAt,
    this.fcmToken,
    this.savedAddresses,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerModel(
      uid: id,
      phoneNumber: map['phoneNumber'] ?? '',
      selectedLocation: map['selectedLocation'] as Map<String, dynamic>?,
      recentLocations: map['recentLocations'] != null
          ? List<Map<String, dynamic>>.from(map['recentLocations'])
          : null,
      locationSource: map['locationSource'],
      locationUpdatedAt: map['locationUpdatedAt'] != null 
          ? (map['locationUpdatedAt'] as Timestamp).toDate() 
          : null,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      fcmToken: map['fcmToken'],
      savedAddresses: map['savedAddresses'] != null 
          ? (map['savedAddresses'] as List).map((a) => AddressModel.fromMap(a as Map<String, dynamic>)).toList() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      if (selectedLocation != null) 'selectedLocation': selectedLocation,
      if (recentLocations != null) 'recentLocations': recentLocations,
      if (locationSource != null) 'locationSource': locationSource,
      if (locationUpdatedAt != null) 'locationUpdatedAt': locationUpdatedAt,
      'createdAt': createdAt,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (savedAddresses != null) 'savedAddresses': savedAddresses!.map((a) => a.toMap()).toList(),
    };
  }

  // Helper getters
  String? get city => selectedLocation?['city'];
  String? get state => selectedLocation?['state'];
  String? get country => selectedLocation?['country'];
  String? get pincode => selectedLocation?['pincode'];
}
