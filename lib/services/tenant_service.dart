import 'package:cloud_firestore/cloud_firestore.dart';

class TenantService {
  final FirebaseFirestore _firestore;

  TenantService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> getStripeCustomerId(String tenantId) async {
    if (tenantId.isEmpty) return null;
    final doc = await _firestore.collection('tenants').doc(tenantId).get();
    if (!doc.exists) return null;
    return doc.data()?['stripeCustomerId'] as String?;
  }

  Stream<Map<String, dynamic>?> watchTenant(String tenantId) {
    if (tenantId.isEmpty) {
      return const Stream<Map<String, dynamic>?>.empty();
    }
    return _firestore.collection('tenants').doc(tenantId).snapshots().map((doc) => doc.data());
  }
}


