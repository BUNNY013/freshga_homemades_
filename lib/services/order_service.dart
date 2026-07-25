import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/refund_request_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

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

  Future<void> submitRefundRequest({
    required OrderModel order,
    required List<OrderItem> items,
    required String reason,
    required String description,
    required List<File> images,
  }) async {
    final String requestId = 'REQ-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    
    // Upload images
    List<String> imageUrls = [];
    print("Starting image upload for ${images.length} images...");
    for (int i = 0; i < images.length; i++) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('refunds')
            .child(order.orderId)
            .child('${requestId}_$i.jpg');
        print("Uploading image $i...");
        await ref.putFile(images[i]);
        final url = await ref.getDownloadURL();
        print("Image $i uploaded: $url");
        imageUrls.add(url);
      } catch (e) {
        print("Error uploading image $i: $e");
        rethrow;
      }
    }
    print("Image upload completed.");

    // Calculate total refund requested
    double refundAmount = 0;
    for (var item in items) {
      refundAmount += (item.price * item.quantity);
    }

    // Create refund request model
    final refundRequest = RefundRequestModel(
      requestId: requestId,
      orderId: order.orderId,
      storeId: order.storeId,
      customerId: order.customerId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      customerAddress: order.deliveryAddress,
      items: items.map((i) => RefundItemModel(
        productId: i.productId,
        productName: i.productName,
        variantLabel: i.variantLabel,
        price: i.price,
        quantity: i.quantity,
      )).toList(),
      reason: reason,
      description: description,
      imageUrls: imageUrls,
      status: 'Pending Vendor',
      refundAmount: refundAmount,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Firestore transactionally
    print("Saving to Firestore...");
    final batch = _firestore.batch();
    final orderRef = _firestore.collection('orders').doc(order.orderId);
    final reqRef = _firestore.collection('refund_requests').doc(requestId);

    batch.set(reqRef, refundRequest.toJson());
    batch.update(orderRef, {
      'isIssueReported': true,
      'issueStatus': 'Pending Vendor',
      'issueId': requestId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
    print("Refund request submitted successfully.");
  }
}
