import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/session_service.dart';

class SessionProvider with ChangeNotifier {
  final SessionService _service;
  final FirebaseAuth _firebaseAuth;
  SessionData? _session;
  bool _isLoading = true;
  Future<void>? _loadingFuture;

  SessionProvider({SessionService? service, FirebaseAuth? firebaseAuth})
      : _service = service ?? SessionService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _loadingFuture = _performLoad();
  }

  SessionData? get session => _session;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _session != null && !_session!.isExpired;
  bool get isAdmin => isAuthenticated && _session!.isAdmin;

  Future<void> _performLoad({bool force = false}) async {
    if (_loadingFuture != null && !force) {
      return _loadingFuture!;
    }
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    final future = () async {
      try {
        final loaded = await _service.load();
        if (loaded != null && loaded.isExpired) {
          await _service.clear();
          _session = null;
        } else {
          _session = loaded;
        }
      } finally {
        _isLoading = false;
        _loadingFuture = null;
        notifyListeners();
      }
    }();

    _loadingFuture = future;
    await future;
  }

  Future<void> load({bool force = false}) => _performLoad(force: force);

  Future<void> login(SessionData data) async {
    _session = data;
    _isLoading = false;
    await _service.save(data);
    notifyListeners();
  }

  Future<void> logout() async {
    _session = null;
    _isLoading = false;
    await _service.clear();
    await _firebaseAuth.signOut();
    notifyListeners();
  }
}


