import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_model.dart';

class CustomerModel {
  final String uid;
  final String phoneNumber;
  final String? fullName;
  final String? email;
  final String? profileImageUrl;
  final Map<String, bool>? notificationPreferences;
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
    this.fullName,
    this.email,
    this.profileImageUrl,
    this.notificationPreferences,
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
      fullName: map['fullName'],
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
      notificationPreferences: map['notificationPreferences'] != null
          ? Map<String, bool>.from(map['notificationPreferences'])
          : {
              'order_updates': true,
              'followed_stores': true,
              'promotional_offers': true,
              'whatsapp_alerts': false,
            },
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
      savedAddresses: () {
        if (map['savedAddresses'] == null) return null;
        final list = (map['savedAddresses'] as List)
            .map((a) => AddressModel.fromMap(a as Map<String, dynamic>))
            .toList();
        bool defaultFound = false;
        return list.map((addr) {
          if (addr.isDefault) {
            if (defaultFound) {
              return addr.copyWith(isDefault: false);
            }
            defaultFound = true;
          }
          return addr;
        }).toList();
      }(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (notificationPreferences != null)
        'notificationPreferences': notificationPreferences,
      if (selectedLocation != null) 'selectedLocation': selectedLocation,
      if (recentLocations != null) 'recentLocations': recentLocations,
      if (locationSource != null) 'locationSource': locationSource,
      if (locationUpdatedAt != null) 'locationUpdatedAt': locationUpdatedAt,
      'createdAt': createdAt,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (savedAddresses != null)
        'savedAddresses': savedAddresses!.map((a) => a.toMap()).toList(),
    };
  }

  // Helper getters
  String? get city => selectedLocation?['city'];
  String? get state => selectedLocation?['state'];
  String? get country => selectedLocation?['country'];
  String? get pincode => selectedLocation?['pincode'];
}
