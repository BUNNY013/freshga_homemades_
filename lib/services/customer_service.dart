import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/address_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or Create Customer
  Future<CustomerModel> getOrCreateCustomer(
    String uid,
    String phoneNumber,
  ) async {
    final docRef = _firestore.collection('customers').doc(uid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      return CustomerModel.fromMap(docSnap.data()!, docSnap.id);
    } else {
      final newCustomer = CustomerModel(
        uid: uid,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );
      await docRef.set(newCustomer.toMap());
      return newCustomer;
    }
  }

  // Stream Customer
  Stream<CustomerModel?> streamCustomer(String uid) {
    return _firestore.collection('customers').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return CustomerModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Update Location
  Future<void> updateLocation({
    required String uid,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required String source,
    required List<Map<String, dynamic>> recentLocations,
  }) async {
    final docRef = _firestore.collection('customers').doc(uid);
    await docRef.set({
      'selectedLocation': {
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
      },
      'recentLocations': recentLocations,
      'locationSource': source,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Save Address
  Future<void> saveAddress(String uid, AddressModel address) async {
    final docRef = _firestore.collection('customers').doc(uid);
    final snapshot = await docRef.get();
    List<dynamic> addresses = [];
    if (snapshot.exists && snapshot.data()?['savedAddresses'] != null) {
      addresses = List<dynamic>.from(snapshot.data()?['savedAddresses']);
    }

    final makeDefault = address.isDefault || addresses.isEmpty;
    if (makeDefault) {
      for (var i = 0; i < addresses.length; i++) {
        final map = Map<String, dynamic>.from(addresses[i]);
        map['isDefault'] = false;
        addresses[i] = map;
      }
    }

    final newMap = address.toMap();
    newMap['isDefault'] = makeDefault;
    addresses.add(newMap);

    await docRef.set({
      'savedAddresses': addresses,
      if (makeDefault)
        'selectedLocation': {
          'city': address.city,
          'state': address.state,
          'country': 'India',
          'pincode': address.pincode,
        },
      if (makeDefault) 'locationSource': 'checkout_address',
    }, SetOptions(merge: true));
  }

  // Remove Address
  Future<void> removeAddress(String uid, String addressId) async {
    final docRef = _firestore.collection('customers').doc(uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final List<dynamic> addresses = List<dynamic>.from(
        snapshot.data()?['savedAddresses'] ?? [],
      );
      addresses.removeWhere((addr) => addr['id'] == addressId);
      await docRef.update({'savedAddresses': addresses});
    }
  }

  // Update Address
  Future<void> updateAddress(String uid, AddressModel updatedAddress) async {
    final docRef = _firestore.collection('customers').doc(uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final List<dynamic> addresses = List<dynamic>.from(
        snapshot.data()?['savedAddresses'] ?? [],
      );
      final index = addresses.indexWhere(
        (addr) => addr['id'] == updatedAddress.id,
      );
      if (index != -1) {
        if (updatedAddress.isDefault) {
          for (var i = 0; i < addresses.length; i++) {
            final map = Map<String, dynamic>.from(addresses[i]);
            map['isDefault'] = false;
            addresses[i] = map;
          }
        }
        addresses[index] = updatedAddress.toMap();

        final updates = <String, dynamic>{'savedAddresses': addresses};
        if (updatedAddress.isDefault) {
          updates['selectedLocation'] = {
            'city': updatedAddress.city,
            'state': updatedAddress.state,
            'country': 'India',
            'pincode': updatedAddress.pincode,
          };
          updates['locationSource'] = 'checkout_address';
        }

        await docRef.update(updates);
      }
    }
  }

  // Set Default Address
  Future<void> setDefaultAddress(String uid, String addressId) async {
    final docRef = _firestore.collection('customers').doc(uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final List<dynamic> addresses = List<dynamic>.from(
        snapshot.data()?['savedAddresses'] ?? [],
      );
      AddressModel? targetAddr;
      for (var i = 0; i < addresses.length; i++) {
        final map = Map<String, dynamic>.from(addresses[i]);
        final isTarget = map['id'] == addressId;
        map['isDefault'] = isTarget;
        addresses[i] = map;
        if (isTarget) {
          targetAddr = AddressModel.fromMap(map);
        }
      }
      final updates = <String, dynamic>{'savedAddresses': addresses};
      if (targetAddr != null) {
        updates['selectedLocation'] = {
          'city': targetAddr.city,
          'state': targetAddr.state,
          'country': 'India',
          'pincode': targetAddr.pincode,
        };
        updates['locationSource'] = 'checkout_address';
      }
      await docRef.update(updates);
    }
  }

  // Update Profile Info
  Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? email,
    String? profileImageUrl,
  }) async {
    final docRef = _firestore.collection('customers').doc(uid);
    final updates = <String, dynamic>{};
    if (fullName != null) updates['fullName'] = fullName;
    if (email != null) updates['email'] = email;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
    if (updates.isNotEmpty) {
      await docRef.set(updates, SetOptions(merge: true));
    }
  }

  // Update Notification Preferences
  Future<void> updateNotificationPreferences({
    required String uid,
    required Map<String, bool> preferences,
  }) async {
    final docRef = _firestore.collection('customers').doc(uid);
    await docRef.set({
      'notificationPreferences': preferences,
    }, SetOptions(merge: true));
  }
}
