import 'dart:convert';

import 'package:app_invv1/services/worker_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('WorkerAuthService', () {
    test('bootstrapWithAccessCode retourne le JSON si status 200', () async {
      final client = MockClient((http.Request request) async {
        expect(request.url.path, '/auth/bootstrap');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['accessCode'], 'admin123');
        expect(body['firebaseUid'], 'uid_1');
        return http.Response(
          jsonEncode({'id': 'u1', 'name': 'Admin', 'tenantId': 't1', 'isAdmin': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = WorkerAuthService(baseUrl: 'https://example.com', client: client);
      final result = await service.bootstrapWithAccessCode(accessCode: 'admin123', firebaseUid: 'uid_1');

      expect(result['tenantId'], 't1');
      expect(result['isAdmin'], true);
    });

    test('bootstrapWithAccessCode lève une exception avec body si status != 2xx', () async {
      final client = MockClient((http.Request request) async {
        return http.Response('Code invalide', 401);
      });

      final service = WorkerAuthService(baseUrl: 'https://example.com', client: client);

      expect(
        () => service.bootstrapWithAccessCode(accessCode: 'bad', firebaseUid: 'uid_1'),
        throwsA(isA<Exception>()),
      );
    });

    test('loginTenant retourne le JSON si status 200', () async {
      final client = MockClient((http.Request request) async {
        expect(request.url.path, '/auth/tenant-login');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'admin@demo.io');
        expect(body['password'], 'admin123');
        expect(body['firebaseUid'], 'uid_2');
        return http.Response(
          jsonEncode({'id': 'admin', 'name': 'Admin', 'tenantId': 'tenant_demo', 'isAdmin': true}),
          200,
        );
      });

      final service = WorkerAuthService(baseUrl: 'https://example.com', client: client);
      final result = await service.loginTenant(email: 'admin@demo.io', password: 'admin123', firebaseUid: 'uid_2');
      expect(result['isAdmin'], true);
    });
  });
}


