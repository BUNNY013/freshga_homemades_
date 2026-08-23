import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'order_update', 'promo', 'system', etc.
  final String? orderId;
  final String? productId;
  final String? storeId;
  final String? imageUrl;
  final bool isUnread;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.orderId,
    this.productId,
    this.storeId,
    this.imageUrl,
    required this.isUnread,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      type: data['type'] ?? 'system',
      orderId: data['orderId'],
      productId: data['productId'],
      storeId: data['storeId'],
      imageUrl: data['imageUrl'],
      isUnread: data['isUnread'] ?? true,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'orderId': orderId,
      'productId': productId,
      'storeId': storeId,
      'imageUrl': imageUrl,
      'isUnread': isUnread,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
