import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import 'users_repository.dart';

class FirestoreUsersRepository implements UsersRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'users';

  FirestoreUsersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<AppUser>> watchUsers({String? tenantId}) {
    Query<Map<String, dynamic>> query = _firestore.collection(_collection);
    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.where('tenantId', isEqualTo: tenantId);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return AppUser.fromMap(data);
        }).toList());
  }

  @override
  Future<int> countUsers({required String tenantId}) async {
    Query<Map<String, dynamic>> query = _firestore.collection(_collection);
    if (tenantId.isNotEmpty) {
      query = query.where('tenantId', isEqualTo: tenantId);
    }
    final snapshot = await query.get();
    return snapshot.docs.length;
  }

  @override
  Future<void> addUser(AppUser user, {required String tenantId}) async {
    final data = user.toMap();
    data['tenantId'] = tenantId;
    data['createdAt'] = FieldValue.serverTimestamp();
    // Utiliser le nom comme ID de document (sanitisé). Garantir l'unicité.
    String baseId = user.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\- ]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    if (baseId.isEmpty) {
      baseId = 'user';
    }
    String docId = baseId;
    int suffix = 1;
    while ((await _firestore.collection(_collection).doc(docId).get()).exists) {
      suffix += 1;
      docId = '${baseId}_$suffix';
    }
    await _firestore.collection(_collection).doc(docId).set(data);
  }

  @override
  Future<void> updateUser(String userId, AppUser user, {required String tenantId}) async {
    final data = user.toMap();
    data['tenantId'] = tenantId;
    await _firestore.collection(_collection).doc(userId).update(data);
  }

  @override
  Future<void> deleteUser(String userId, {required String tenantId}) async {
    await _firestore.collection(_collection).doc(userId).delete();
  }

  @override
  Future<bool> isCodeAvailable(String code, {required String tenantId}) async {
    final snap = await _firestore
        .collection(_collection)
        .where('code', isEqualTo: code)
        .where('tenantId', isEqualTo: tenantId)
        .limit(1)
        .get();
    return snap.docs.isEmpty;
  }
}


