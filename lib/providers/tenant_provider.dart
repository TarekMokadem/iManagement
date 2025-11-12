import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/tenant_service.dart';

class TenantProvider with ChangeNotifier {
  final TenantService _tenantService;

  String? _tenantId;
  String _plan = 'free';
  Map<String, dynamic> _entitlements = const {};
  String? _stripeCustomerId;
  StreamSubscription<Map<String, dynamic>?>? _tenantSubscription;

  TenantProvider({TenantService? tenantService})
      : _tenantService = tenantService ?? TenantService();

  String? get tenantId => _tenantId;
  String get plan => _plan;
  Map<String, dynamic> get entitlements => _entitlements;
  String? get stripeCustomerId => _stripeCustomerId;

  void setTenant({required String tenantId}) {
    if (tenantId.isEmpty) {
      clearTenant();
      return;
    }
    if (_tenantId == tenantId) return;
    _tenantId = tenantId;
    notifyListeners();
    _listenToTenant();
  }

  void clearTenant() {
    _tenantSubscription?.cancel();
    _tenantSubscription = null;

    final hasChanges = _tenantId != null ||
        _stripeCustomerId != null ||
        _plan != 'free' ||
        _entitlements.isNotEmpty;

    _tenantId = null;
    _stripeCustomerId = null;
    _plan = 'free';
    _entitlements = const {};

    if (hasChanges) {
      notifyListeners();
    }
  }

  void _listenToTenant() {
    _tenantSubscription?.cancel();
    final currentTenant = _tenantId;
    if (currentTenant == null || currentTenant.isEmpty) {
      return;
    }
    _tenantSubscription = _tenantService.watchTenant(currentTenant).listen(
      (data) {
        final newPlan = (data?['plan'] as String?) ?? 'free';
        final rawEntitlements = data?['entitlements'];
        final newEntitlements = rawEntitlements is Map<String, dynamic>
            ? Map<String, dynamic>.from(rawEntitlements)
            : const <String, dynamic>{};
        final newCustomerId = data?['stripeCustomerId'] as String?;

        var shouldNotify = false;
        if (_plan != newPlan) {
          _plan = newPlan;
          shouldNotify = true;
        }
        if (!mapEquals(_entitlements, newEntitlements)) {
          _entitlements = newEntitlements;
          shouldNotify = true;
        }
        if (_stripeCustomerId != newCustomerId) {
          _stripeCustomerId = newCustomerId;
          shouldNotify = true;
        }
        if (shouldNotify) {
          notifyListeners();
        }
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Erreur écoute tenant $currentTenant: $error');
      },
    );
  }

  @override
  void dispose() {
    _tenantSubscription?.cancel();
    super.dispose();
  }
}


