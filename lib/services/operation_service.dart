import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/operation.dart';

class OperationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'operations';

  // Récupérer toutes les opérations
  Stream<List<Operation>> getAllOperations() {
    return _firestore
        .collection(_collection)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Operation.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Récupérer les opérations d'un produit spécifique
  Stream<List<Operation>> getOperationsByProduct(String productId) {
    return _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Operation.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Ajouter une nouvelle opération
  Future<void> addOperation(Operation operation) async {
    await _firestore.collection(_collection).add(operation.toMap());
  }

  // Récupérer les opérations d'un utilisateur spécifique
  Stream<List<Operation>> getOperationsByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Operation.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Récupérer les opérations par date
  Stream<List<Operation>> getOperationsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_collection)
        .where('dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Operation.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Récupérer les opérations par type
  Stream<List<Operation>> getOperationsByType(OperationType type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Operation.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Récupérer les ajouts
  Stream<List<Operation>> getEntryOperations() {
    return getOperationsByType(OperationType.entree);
  }

  // Récupérer les retraits
  Stream<List<Operation>> getExitOperations() {
    return getOperationsByType(OperationType.sortie);
  }

  Future<void> deleteOperation(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
} 