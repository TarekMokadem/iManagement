import 'package:cloud_firestore/cloud_firestore.dart';

class Alert {
  final String id;
  final String productId;
  final String productName;
  final DateTime timestamp;
  final String status;
  final Map<String, dynamic> notification;

  Alert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.timestamp,
    required this.status,
    required this.notification,
  });

  factory Alert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Alert(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      notification: data['notification'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'notification': notification,
    };
  }
} 