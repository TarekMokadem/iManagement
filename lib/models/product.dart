import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String location;
  final int quantity;
  final int criticalThreshold;
  final DateTime lastUpdated;

  Product({
    required this.id,
    required this.name,
    required this.location,
    required this.quantity,
    required this.criticalThreshold,
    required this.lastUpdated,
  });

  bool get isCritical => quantity <= criticalThreshold;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'quantity': quantity,
      'criticalThreshold': criticalThreshold,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else {
        throw const FormatException('Format de date invalide');
      }
    }

    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String,
      quantity: map['quantity'] as int,
      criticalThreshold: map['criticalThreshold'] as int,
      lastUpdated: parseDate(map['lastUpdated']),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? location,
    int? quantity,
    int? criticalThreshold,
    DateTime? lastUpdated,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
} 