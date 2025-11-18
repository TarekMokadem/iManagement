import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inscription : crée un tenant + user admin
  Future<Map<String, String>> signup({
    required String name,
    required String email,
    required String password,
    required String companyName,
  }) async {
    // Vérifier si l'email existe déjà
    final existingUsers = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .get();

    if (existingUsers.docs.isNotEmpty) {
      throw Exception('Cet email est déjà utilisé');
    }

    // Créer le tenant
    final tenantRef = await _firestore.collection('tenants').add({
      'name': companyName,
      'plan': 'free',
      'createdAt': FieldValue.serverTimestamp(),
      'entitlements': {
        'maxUsers': 3,
        'maxProducts': 200,
        'maxOperationsPerMonth': 1000,
        'exports': 'false',
        'support': 'community',
      },
      'billingStatus': 'active',
    });

    final tenantId = tenantRef.id;

    // Hasher le mot de passe
    final hashedPassword = _hashPassword(password);

    // Créer l'utilisateur admin avec ID = nom
    final userDocId = _sanitizeId(name);
    await _firestore.collection('users').doc(userDocId).set({
      'name': name,
      'email': email.toLowerCase(),
      'password': hashedPassword,
      'tenantId': tenantId,
      'isAdmin': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'userId': userDocId,
      'userName': name,
      'tenantId': tenantId,
    };
  }

  /// Connexion : vérifie email + password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Email ou mot de passe incorrect');
    }

    final userDoc = snapshot.docs.first;
    final userData = userDoc.data();
    final storedHash = userData['password'] as String?;

    if (storedHash == null || storedHash != _hashPassword(password)) {
      throw Exception('Email ou mot de passe incorrect');
    }

    return {
      'id': userDoc.id,
      'name': userData['name'] as String,
      'email': userData['email'] as String,
      'tenantId': userData['tenantId'] as String,
      'isAdmin': userData['isAdmin'] as bool? ?? false,
    };
  }

  /// Connexion dédiée aux comptes tenant/admin
  Future<Map<String, dynamic>> loginTenant({
    required String email,
    required String password,
  }) async {
    final user = await login(email: email, password: password);
    final isAdmin = user['isAdmin'] as bool? ?? false;
    if (!isAdmin) {
      throw Exception('Seuls les administrateurs peuvent accéder à cet espace.');
    }

    final tenantId = user['tenantId'] as String?;
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Aucun tenant associé à ce compte.');
    }

    final tenantDoc = await _firestore.collection('tenants').doc(tenantId).get();
    if (!tenantDoc.exists) {
      throw Exception('Espace client introuvable pour ce compte.');
    }

    return {
      ...user,
      'tenant': tenantDoc.data(),
    };
  }

  /// Connexion par code d'accès (utilisateurs de l'application)
  Future<Map<String, dynamic>> loginWithAccessCode(String accessCode) async {
    final snap = await _firestore
        .collection('users')
        .where('code', isEqualTo: accessCode)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('Code d’accès invalide');
    }
    final doc = snap.docs.first;
    final data = doc.data();
    return {
      'id': doc.id,
      'name': data['name'] as String,
      'email': data['email'] as String?,
      'tenantId': data['tenantId'] as String,
      'isAdmin': data['isAdmin'] as bool? ?? false,
    };
  }

  String _sanitizeId(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\- ]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  /// Hash simple du mot de passe (SHA-256)
  /// ⚠️ En production, utiliser Firebase Auth ou un système plus robuste
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
