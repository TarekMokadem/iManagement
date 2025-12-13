import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/worker_config.dart';

class TenantPortalService {
  final String baseUrl;
  final http.Client _client;

  TenantPortalService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? WorkerConfig.baseUrl,
        _client = client ?? http.Client();

  Future<void> updateTenantProfile({
    required String tenantId,
    required String firebaseUid,
    String? name,
    String? contactEmail,
  }) async {
    final url = Uri.parse('$baseUrl/tenant/update-profile');
    final payload = <String, dynamic>{
      'tenantId': tenantId,
      'firebaseUid': firebaseUid,
      if (name != null) 'name': name,
      if (contactEmail != null) 'contactEmail': contactEmail,
    };

    final resp = await _client.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return;
    }
    throw Exception(resp.body.isNotEmpty ? resp.body : 'Erreur update profil (${resp.statusCode})');
  }
}


