import 'package:firebase_auth/firebase_auth.dart';

import 'worker_auth_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final WorkerAuthService _workerAuthService;

  AuthService({FirebaseAuth? firebaseAuth, WorkerAuthService? workerAuthService})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _workerAuthService = workerAuthService ?? WorkerAuthService();

  /// Inscription : crée un tenant + user admin
  Future<Map<String, String>> signup({
    required String name,
    required String email,
    required String password,
    required String companyName,
  }) async {
    final firebaseUid = await _ensureFirebaseSignedIn();
    final result = await _workerAuthService.signup(
      name: name,
      email: email.trim().toLowerCase(),
      password: password,
      companyName: companyName,
      firebaseUid: firebaseUid,
    );
    return {
      'userId': result['userId'] as String,
      'userName': result['userName'] as String,
      'tenantId': result['tenantId'] as String,
    };
  }

  Future<String> _ensureFirebaseSignedIn() async {
    final current = _firebaseAuth.currentUser;
    if (current != null) return current.uid;
    final cred = await _firebaseAuth.signInAnonymously();
    final user = cred.user;
    if (user == null) {
      throw Exception('Impossible de démarrer une session sécurisée.');
    }
    return user.uid;
  }

  /// Connexion dédiée aux comptes tenant/admin
  Future<Map<String, dynamic>> loginTenant({
    required String email,
    required String password,
  }) async {
    final firebaseUid = await _ensureFirebaseSignedIn();
    return _workerAuthService.loginTenant(
      email: email,
      password: password,
      firebaseUid: firebaseUid,
    );
  }

  /// Connexion par code d'accès (utilisateurs de l'application)
  Future<Map<String, dynamic>> loginWithAccessCode(String accessCode) async {
    final firebaseUid = await _ensureFirebaseSignedIn();
    return _workerAuthService.bootstrapWithAccessCode(
      accessCode: accessCode,
      firebaseUid: firebaseUid,
    );
  }
}
