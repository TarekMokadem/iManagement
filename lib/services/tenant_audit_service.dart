import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TenantAuditService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TenantAuditService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> log({
    required String tenantId,
    required String action,
    String? actorName,
    Map<String, dynamic>? meta,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    await _firestore.collection('tenant_audit').add({
      'tenantId': tenantId,
      'action': action,
      'actorUid': uid,
      if (actorName != null) 'actorName': actorName,
      if (meta != null) 'meta': meta,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchRecent({required String tenantId, int limit = 50}) {
    return _firestore
        .collection('tenant_audit')
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(1, 200))
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
              .toList(growable: false),
        );
  }
}


