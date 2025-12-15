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
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    String _asString(dynamic v) => v == null ? '' : v.toString();
    bool _asBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    final rawCreatedAt = map['createdAt'];
    DateTime? createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }
    return AppUser(
      id: _asString(map['id']),
      name: _asString(map['name']),
      code: _asString(map['code']),
      isAdmin: _asBool(map['isAdmin']),
      tenantId: _asString(map['tenantId']).isEmpty ? 'default' : _asString(map['tenantId']),
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