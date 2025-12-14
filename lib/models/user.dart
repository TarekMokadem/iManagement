import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String code;
  final bool isAdmin;
  final String tenantId;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.code,
    required this.isAdmin,
    required this.tenantId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'isAdmin': isAdmin,
      'tenantId': tenantId,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    DateTime? createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      isAdmin: (map['isAdmin'] as bool?) ?? false,
      tenantId: (map['tenantId'] as String?) ?? 'default',
      createdAt: createdAt,
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? code,
    bool? isAdmin,
    String? tenantId,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      isAdmin: isAdmin ?? this.isAdmin,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 