import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late SharedPreferences _prefs;
  static const String _attemptsKey = 'login_attempts';
  static const String _lastAttemptTimeKey = 'last_attempt_time';
  static const int _maxAttempts = 10;
  static const int _blockDurationMinutes = 15;

  AuthService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<AppUser> login(String code) async {
    // Vérifier si l'utilisateur est bloqué
    if (await _isUserBlocked()) {
      throw 'Trop de tentatives de connexion. Veuillez réessayer dans ${_getRemainingBlockTime()} minutes.';
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await _incrementAttempts();
        throw 'Code invalide';
      }

      // Réinitialiser les tentatives en cas de succès
      await _resetAttempts();

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      userData['id'] = userDoc.id;
      return AppUser.fromMap(userData);
    } catch (e) {
      if (e is! String) {
        await _incrementAttempts();
        throw 'Une erreur est survenue lors de la connexion';
      }
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    // Vérifier si l'utilisateur est bloqué
    if (await _isUserBlocked()) {
      throw 'Trop de tentatives de connexion. Veuillez réessayer dans ${_getRemainingBlockTime()} minutes.';
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Réinitialiser les tentatives en cas de succès
      await _resetAttempts();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Incrémenter le nombre de tentatives en cas d'échec
      await _incrementAttempts();
      throw e.message ?? 'Une erreur est survenue lors de la connexion';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> _isUserBlocked() async {
    final attempts = _prefs.getInt(_attemptsKey) ?? 0;
    if (attempts >= _maxAttempts) {
      final lastAttemptTime = _prefs.getInt(_lastAttemptTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final blockDuration = _blockDurationMinutes * 60 * 1000; // Convertir en millisecondes
      
      if (now - lastAttemptTime < blockDuration) {
        return true;
      } else {
        // Réinitialiser si le temps de blocage est écoulé
        await _resetAttempts();
        return false;
      }
    }
    return false;
  }

  Future<void> _incrementAttempts() async {
    final attempts = (_prefs.getInt(_attemptsKey) ?? 0) + 1;
    await _prefs.setInt(_attemptsKey, attempts);
    await _prefs.setInt(_lastAttemptTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _resetAttempts() async {
    await _prefs.setInt(_attemptsKey, 0);
    await _prefs.setInt(_lastAttemptTimeKey, 0);
  }

  int _getRemainingBlockTime() {
    final lastAttemptTime = _prefs.getInt(_lastAttemptTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final blockDuration = _blockDurationMinutes * 60 * 1000;
    final remainingTime = (blockDuration - (now - lastAttemptTime)) ~/ (60 * 1000);
    return remainingTime > 0 ? remainingTime : 0;
  }

  Future<int> getRemainingAttempts() async {
    return _maxAttempts - (_prefs.getInt(_attemptsKey) ?? 0);
  }
} 