import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionData {
  final String userId;
  final String userName;
  final String tenantId;
  final bool isAdmin;
  final DateTime expiresAt;

  SessionData({
    required this.userId,
    required this.userName,
    required this.tenantId,
    required this.isAdmin,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'tenantId': tenantId,
        'isAdmin': isAdmin,
        'expiresAt': expiresAt.toIso8601String(),
      };

  static SessionData? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return SessionData(
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      tenantId: map['tenantId'] as String,
      isAdmin: map['isAdmin'] as bool,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }
}

class SessionService {
  static const _key = 'app_session_v1';

  Future<void> save(SessionData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(data.toMap());
    await prefs.setString(_key, jsonStr);
  }

  Future<SessionData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SessionData.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}


