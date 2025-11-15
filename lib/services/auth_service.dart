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

    // Créer l'utilisateur admin
    final userRef = await _firestore.collection('users').add({
      'name': name,
      'email': email.toLowerCase(),
      'password': hashedPassword,
      'tenantId': tenantId,
      'isAdmin': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'userId': userRef.id,
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

  /// Hash simple du mot de passe (SHA-256)
  /// ⚠️ En production, utiliser Firebase Auth ou un système plus robuste
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
