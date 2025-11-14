import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/tenant_service.dart';

class TenantProvider with ChangeNotifier {
  final TenantService _tenantService;

  String? _tenantId;
  String _plan = 'free';
  Map<String, dynamic> _entitlements = const {};
  String? _stripeCustomerId;
  String _billingStatus = 'active';
  String? _billingLastPaymentError;
  DateTime? _billingCurrentPeriodEnd;
  StreamSubscription<Map<String, dynamic>?>? _tenantSubscription;

  TenantProvider({TenantService? tenantService})
      : _tenantService = tenantService ?? TenantService();

  String? get tenantId => _tenantId;
  String get plan => _plan;
  Map<String, dynamic> get entitlements => _entitlements;
  String? get stripeCustomerId => _stripeCustomerId;
  String get billingStatus => _billingStatus;
  String? get billingLastPaymentError => _billingLastPaymentError;
  DateTime? get billingCurrentPeriodEnd => _billingCurrentPeriodEnd;

  bool get hasPaymentIssue => _billingStatus == 'payment_failed' || _billingStatus == 'past_due';

  int? get maxUsers => _intFromEntitlement('maxUsers');
  int? get maxProducts => _intFromEntitlement('maxProducts');
  int? get maxOperationsPerMonth => _intFromEntitlement('maxOperationsPerMonth');

  int? _intFromEntitlement(String key) {
    final value = _entitlements[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

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
        _entitlements.isNotEmpty ||
        _billingStatus != 'active';

    _tenantId = null;
    _stripeCustomerId = null;
    _plan = 'free';
    _entitlements = const {};
    _billingStatus = 'active';
    _billingLastPaymentError = null;
    _billingCurrentPeriodEnd = null;

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
        final newBillingStatus = (data?['billingStatus'] as String?) ?? 'active';
        final newPaymentError = data?['billingLastPaymentError'] as String?;
        final rawPeriodEnd = data?['billingCurrentPeriodEnd'];
        final newPeriodEnd = rawPeriodEnd is String ? DateTime.tryParse(rawPeriodEnd) : null;

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
        if (_billingStatus != newBillingStatus) {
          _billingStatus = newBillingStatus;
          shouldNotify = true;
        }
        if (_billingLastPaymentError != newPaymentError) {
          _billingLastPaymentError = newPaymentError;
          shouldNotify = true;
        }
        if (_billingCurrentPeriodEnd != newPeriodEnd) {
          _billingCurrentPeriodEnd = newPeriodEnd;
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


