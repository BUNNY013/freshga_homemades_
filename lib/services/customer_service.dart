import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/address_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or Create Customer
  Future<CustomerModel> getOrCreateCustomer(String uid, String phoneNumber) async {
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
    
    // First, check if we want to set this as default (if it's the first one, or explicitly set)
    // If it's default, we might also want to update the selectedLocation to match it automatically.
    
    await docRef.set({
      'savedAddresses': FieldValue.arrayUnion([address.toMap()]),
      if (address.isDefault) 
        'selectedLocation': {
          'city': address.city,
          'state': address.state,
          'country': 'India',
          'pincode': address.pincode,
        },
      if (address.isDefault)
        'locationSource': 'checkout_address',
    }, SetOptions(merge: true));
  }

  // Remove Address
  Future<void> removeAddress(String uid, String addressId) async {
    final docRef = _firestore.collection('customers').doc(uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final List<dynamic> addresses = snapshot.data()?['savedAddresses'] ?? [];
      addresses.removeWhere((addr) => addr['id'] == addressId);
      await docRef.update({'savedAddresses': addresses});
    }
  }

  // Update Address
  Future<void> updateAddress(String uid, AddressModel updatedAddress) async {
    final docRef = _firestore.collection('customers').doc(uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final List<dynamic> addresses = snapshot.data()?['savedAddresses'] ?? [];
      final index = addresses.indexWhere((addr) => addr['id'] == updatedAddress.id);
      if (index != -1) {
        addresses[index] = updatedAddress.toMap();
        await docRef.update({'savedAddresses': addresses});
      }
    }
  }
}
