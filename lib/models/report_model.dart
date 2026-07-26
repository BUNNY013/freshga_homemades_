import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String type; // 'store', 'product_before_order', 'product_after_order'
  final String targetId; // storeId or productId
  final String targetName; // storeName or productName
  final String storeId;
  final String reporterUserId;
  final String reporterName;
  final String reason;
  final String comments;
  final String status; // 'open', 'resolved', 'dismissed'
  final String? orderId;
  final DateTime createdAt;

  ReportModel({
    required this.reportId,
    required this.type,
    required this.targetId,
    required this.targetName,
    required this.storeId,
    required this.reporterUserId,
    required this.reporterName,
    required this.reason,
    required this.comments,
    this.status = 'open',
    this.orderId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'type': type,
      'targetId': targetId,
      'targetName': targetName,
      'storeId': storeId,
      'reporterUserId': reporterUserId,
      'reporterName': reporterName,
      'reason': reason,
      'comments': comments,
      'status': status,
      'orderId': orderId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReportModel(
      reportId: map['reportId'] ?? docId,
      type: map['type'] ?? 'store',
      targetId: map['targetId'] ?? '',
      targetName: map['targetName'] ?? 'Unknown Target',
      storeId: map['storeId'] ?? '',
      reporterUserId: map['reporterUserId'] ?? '',
      reporterName: map['reporterName'] ?? 'Customer',
      reason: map['reason'] ?? '',
      comments: map['comments'] ?? '',
      status: map['status'] ?? 'open',
      orderId: map['orderId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
