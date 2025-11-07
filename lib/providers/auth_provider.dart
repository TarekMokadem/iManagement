import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isAdmin = false;

  User? get user => _user;
  bool get isAdmin => _isAdmin;

  Future<bool> loginWithCode(String code) async {
    try {
      // Vérifier le code dans Firestore
      final userDoc = await _firestore
          .collection('users')
          .where('code', isEqualTo: code)
          .get();

      if (userDoc.docs.isEmpty) {
        return false;
      }

      final userData = userDoc.docs.first.data();
      _isAdmin = userData['isAdmin'] ?? false;
      
      // Créer un compte anonyme pour la session
      final userCredential = await _auth.signInAnonymously();
      _user = userCredential.user;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _isAdmin = false;
    notifyListeners();
  }
} 