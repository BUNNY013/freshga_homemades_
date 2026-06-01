import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

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
}
