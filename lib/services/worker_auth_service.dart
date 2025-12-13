import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/worker_config.dart';

class WorkerAuthService {
  final String baseUrl;
  final http.Client _client;

  WorkerAuthService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? WorkerConfig.baseUrl,
        _client = client ?? http.Client();

  Future<Map<String, dynamic>> bootstrapWithAccessCode({
    required String accessCode,
    required String firebaseUid,
  }) async {
    final url = Uri.parse('$baseUrl/auth/bootstrap');
    final resp = await _client.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accessCode': accessCode,
        'firebaseUid': firebaseUid,
      }),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception(resp.body.isNotEmpty ? resp.body : 'Erreur auth (${resp.statusCode})');
  }

  Future<Map<String, dynamic>> loginTenant({
    required String email,
    required String password,
    required String firebaseUid,
  }) async {
    final url = Uri.parse('$baseUrl/auth/tenant-login');
    final resp = await _client.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'firebaseUid': firebaseUid,
      }),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception(resp.body.isNotEmpty ? resp.body : 'Erreur auth (${resp.statusCode})');
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String companyName,
    required String firebaseUid,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    final resp = await _client.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'companyName': companyName,
        'firebaseUid': firebaseUid,
      }),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception(resp.body.isNotEmpty ? resp.body : 'Erreur inscription (${resp.statusCode})');
  }
}


