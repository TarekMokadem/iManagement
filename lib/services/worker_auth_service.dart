import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/worker_config.dart';
import '../debug/remote_logger.dart';

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
    RemoteLogger.log(
      hypothesisId: 'H2',
      location: 'lib/services/worker_auth_service.dart:bootstrapWithAccessCode',
      message: 'POST auth bootstrap',
      data: {
        'baseUrl': baseUrl,
        'path': url.path,
        'firebaseUidPrefix': firebaseUid.length >= 6 ? firebaseUid.substring(0, 6) : firebaseUid,
        'firebaseUidLen': firebaseUid.length,
        'accessCodeLen': accessCode.length, // no secret
      },
    );
    final resp = await _client.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accessCode': accessCode,
        'firebaseUid': firebaseUid,
      }),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      RemoteLogger.log(
        hypothesisId: 'H1',
        location: 'lib/services/worker_auth_service.dart:bootstrapWithAccessCode',
        message: 'auth bootstrap success',
        data: {'status': resp.statusCode},
      );
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    RemoteLogger.log(
      hypothesisId: 'H1',
      location: 'lib/services/worker_auth_service.dart:bootstrapWithAccessCode',
      message: 'auth bootstrap failed',
      data: {
        'status': resp.statusCode,
        'bodyPrefix': resp.body.length > 80 ? resp.body.substring(0, 80) : resp.body,
      },
    );
    throw Exception(resp.body.isNotEmpty ? resp.body : 'Erreur auth (${resp.statusCode})');
  }

  Future<Map<String, dynamic>> loginTenant({
    required String email,
    required String password,
    required String firebaseUid,
  }) async {
    final url = Uri.parse('$baseUrl/auth/tenant-login');
    RemoteLogger.log(
      hypothesisId: 'H2',
      location: 'lib/services/worker_auth_service.dart:loginTenant',
      message: 'POST tenant-login',
      data: {
        'baseUrl': baseUrl,
        'path': url.path,
        'emailDomain': email.contains('@') ? email.split('@').last : 'invalid',
        'firebaseUidPrefix': firebaseUid.length >= 6 ? firebaseUid.substring(0, 6) : firebaseUid,
        'firebaseUidLen': firebaseUid.length,
        'passwordLen': password.length, // no secret
      },
    );
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
      RemoteLogger.log(
        hypothesisId: 'H1',
        location: 'lib/services/worker_auth_service.dart:loginTenant',
        message: 'tenant-login success',
        data: {'status': resp.statusCode},
      );
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    RemoteLogger.log(
      hypothesisId: 'H1',
      location: 'lib/services/worker_auth_service.dart:loginTenant',
      message: 'tenant-login failed',
      data: {
        'status': resp.statusCode,
        'bodyPrefix': resp.body.length > 80 ? resp.body.substring(0, 80) : resp.body,
      },
    );
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


