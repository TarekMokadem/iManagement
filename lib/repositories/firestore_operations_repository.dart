import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/operation.dart';
import 'operations_repository.dart';

class FirestoreOperationsRepository implements OperationsRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'operations';

  FirestoreOperationsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Query<Map<String, dynamic>> _baseQuery(String tenantId) {
    return _firestore
        .collection(_collection)
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('dateTime', descending: true);
  }

  @override
  Stream<List<Operation>> watchAll({required String tenantId}) {
    return _baseQuery(tenantId).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Operation.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  @override
  Stream<List<Operation>> watchByDate(DateTime date, {required String tenantId}) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _firestore
        .collection(_collection)
        .where('tenantId', isEqualTo: tenantId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Operation.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  @override
  Stream<List<Operation>> watchByType(OperationType type, {required String tenantId}) {
    return _firestore
        .collection(_collection)
        .where('tenantId', isEqualTo: tenantId)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Operation.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  @override
  Stream<List<Operation>> watchByProduct(String productId, {required String tenantId}) {
    return _firestore
        .collection(_collection)
        .where('tenantId', isEqualTo: tenantId)
        .where('productId', isEqualTo: productId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Operation.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  @override
  Stream<List<Operation>> watchByUser(String userId, {required String tenantId}) {
    return _firestore
        .collection(_collection)
        .where('tenantId', isEqualTo: tenantId)
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Operation.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  @override
  Future<void> add(Operation operation, {required String tenantId}) async {
    final data = operation.toMap();
    data['tenantId'] = tenantId;
    await _firestore.collection(_collection).add(data);
  }

  @override
  Future<void> delete(String id, {required String tenantId}) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}


