import 'package:flutter/material.dart';

class TenantProvider with ChangeNotifier {
  String? _tenantId;
  String _plan = 'free';
  Map<String, dynamic> _entitlements = const {};

  String? get tenantId => _tenantId;
  String get plan => _plan;
  Map<String, dynamic> get entitlements => _entitlements;

  void setTenant({required String tenantId}) {
    if (_tenantId == tenantId) return;
    _tenantId = tenantId;
    notifyListeners();
  }

  void setPlan(String plan) {
    if (_plan == plan) return;
    _plan = plan;
    notifyListeners();
  }

  void setEntitlements(Map<String, dynamic> entitlements) {
    _entitlements = Map<String, dynamic>.from(entitlements);
    notifyListeners();
  }
}


