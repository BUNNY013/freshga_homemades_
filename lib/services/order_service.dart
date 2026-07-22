import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createOrder(OrderModel order) async {
    final DocumentReference counterRef = _firestore.collection('counters').doc('orders');
    
    return await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot counterSnapshot = await transaction.get(counterRef);
      
      int currentId = 10000; // Starting ID
      if (counterSnapshot.exists) {
        final data = counterSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('lastOrderId')) {
          currentId = data['lastOrderId'] as int;
        }
      }
      
      final int nextId = currentId + 1;
      final String formattedOrderId = 'ORD-$nextId';
      
      // Update counter
      transaction.set(counterRef, {'lastOrderId': nextId}, SetOptions(merge: true));
      
      // Prepare final order with the generated ID
      final finalOrder = order.copyWith(
        orderId: formattedOrderId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Create new order document using the generated ID as the document ID
      final DocumentReference orderRef = _firestore.collection('orders').doc(formattedOrderId);
      transaction.set(orderRef, finalOrder.toJson());
      
      return formattedOrderId;
    });
  }
}
