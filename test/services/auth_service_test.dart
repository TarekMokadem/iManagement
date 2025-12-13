import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_invv1/services/auth_service.dart';
import 'package:app_invv1/services/worker_auth_service.dart';

class _FakeWorkerAuthService extends WorkerAuthService {
  _FakeWorkerAuthService();

  String? lastAccessCode;
  String? lastFirebaseUid;
  String? lastEmail;
  String? lastPassword;

  Map<String, dynamic> bootstrapResponse = const {
    'id': 'u1',
    'name': 'Employé',
    'tenantId': 't1',
    'isAdmin': false,
  };

  Map<String, dynamic> tenantLoginResponse = const {
    'id': 'admin1',
    'name': 'Admin',
    'email': 'admin@demo.io',
    'tenantId': 't1',
    'isAdmin': true,
  };

  @override
  Future<Map<String, dynamic>> bootstrapWithAccessCode({
    required String accessCode,
    required String firebaseUid,
  }) async {
    lastAccessCode = accessCode;
    lastFirebaseUid = firebaseUid;
    return bootstrapResponse;
  }

  @override
  Future<Map<String, dynamic>> loginTenant({
    required String email,
    required String password,
    required String firebaseUid,
  }) async {
    lastEmail = email;
    lastPassword = password;
    lastFirebaseUid = firebaseUid;
    return tenantLoginResponse;
  }
}

void main() {
  group('AuthService (Firebase anonyme + Worker bootstrap)', () {
    test('loginWithAccessCode appelle Worker avec firebaseUid', () async {
      final firebaseAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'uid_123'),
      );
      final worker = _FakeWorkerAuthService();
      final auth = AuthService(firebaseAuth: firebaseAuth, workerAuthService: worker);

      final result = await auth.loginWithAccessCode('emp123');

      expect(worker.lastAccessCode, 'emp123');
      expect(worker.lastFirebaseUid, 'uid_123');
      expect(result['tenantId'], 't1');
    });

    test('loginTenant appelle Worker avec firebaseUid', () async {
      final firebaseAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'uid_admin'),
      );
      final worker = _FakeWorkerAuthService();
      final auth = AuthService(firebaseAuth: firebaseAuth, workerAuthService: worker);

      final result = await auth.loginTenant(email: 'admin@demo.io', password: 'admin123');

      expect(worker.lastEmail, 'admin@demo.io');
      expect(worker.lastPassword, 'admin123');
      expect(worker.lastFirebaseUid, 'uid_admin');
      expect(result['isAdmin'], true);
    });
  });
}


