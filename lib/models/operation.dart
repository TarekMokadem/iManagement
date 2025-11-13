import 'package:cloud_firestore/cloud_firestore.dart';

enum OperationType {
  entree,
  sortie;

  String toLowerCase() => toString().split('.').last;
  int compareTo(OperationType other) => toString().compareTo(other.toString());
}

class Operation {
  final String id;
  final String tenantId;
  final String productId;
  final String productName;
  final OperationType type;
  final int quantity;
  final DateTime dateTime;
  final String userId;
  final String userName;

  Operation({
    required this.id,
    required this.tenantId,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.dateTime,
    required this.userId,
    required this.userName,
  });

  DateTime get date => dateTime;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'productId': productId,
      'productName': productName,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'dateTime': Timestamp.fromDate(dateTime),
      'userId': userId,
      'userName': userName,
    };
  }

  factory Operation.fromMap(Map<String, dynamic> map) {
    return Operation(
      id: map['id'] as String,
      tenantId: (map['tenantId'] as String?) ?? '',
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      type: OperationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      quantity: map['quantity'] as int,
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      userId: map['userId'] as String,
      userName: map['userName'] as String,
    );
  }

  Operation copyWith({
    String? id,
    String? tenantId,
    String? productId,
    String? productName,
    OperationType? type,
    int? quantity,
    DateTime? dateTime,
    String? userId,
    String? userName,
  }) {
    return Operation(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      dateTime: dateTime ?? this.dateTime,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }
} 