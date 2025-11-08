import 'package:flutter/material.dart';

import '../services/session_service.dart';

class SessionProvider with ChangeNotifier {
  final SessionService _service;
  SessionData? _session;

  SessionProvider({SessionService? service}) : _service = service ?? SessionService();

  SessionData? get session => _session;
  bool get isAuthenticated => _session != null && !_session!.isExpired;
  bool get isAdmin => isAuthenticated && _session!.isAdmin;

  Future<void> load() async {
    _session = await _service.load();
    if (_session != null && _session!.isExpired) {
      await logout();
      return;
    }
    notifyListeners();
  }

  Future<void> login(SessionData data) async {
    _session = data;
    await _service.save(data);
    notifyListeners();
  }

  Future<void> logout() async {
    _session = null;
    await _service.clear();
    notifyListeners();
  }
}


