import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/operation.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // Obtenir tous les produits
  Stream<List<Product>> getAllProducts({required String tenantId}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_collection).orderBy('lastUpdated', descending: true);
    if (tenantId.isNotEmpty) {
      query = query.where('tenantId', isEqualTo: tenantId);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  // Obtenir les produits critiques
  Stream<List<Product>> getCriticalProducts({required String tenantId}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_collection).orderBy('lastUpdated', descending: true);
    if (tenantId.isNotEmpty) {
      query = query.where('tenantId', isEqualTo: tenantId);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
        .where((product) => product.isCritical)
        .toList());
  }

  // Ajouter un nouveau produit
  Future<void> addProduct(Product product, {required String tenantId}) async {
    final data = product.toMap();
    data['tenantId'] = tenantId;
    await _firestore.collection(_collection).add(data);
  }

  // Mettre à jour un produit
  Future<void> updateProduct(String id, Product product, {String? tenantId}) async {
    final data = product.toMap();
    if (tenantId != null && tenantId.isNotEmpty) {
      data['tenantId'] = tenantId;
    }
    await _firestore.collection(_collection).doc(id).update(data);
  }

  // Supprimer un produit
  Future<void> deleteProduct(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Mettre à jour la quantité d'un produit
  Future<void> updateQuantity(
    Product product,
    int newQuantity,
    String userId,
    String userName,
    String tenantId,
  ) async {
    final oldQuantity = product.quantity;
    final difference = newQuantity - oldQuantity;
    
    // Mettre à jour le produit
    final updatedProduct = product.copyWith(
      quantity: newQuantity,
      lastUpdated: DateTime.now(),
    );
    
    // Créer une opération avec un ID unique
    final operation = Operation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tenantId: tenantId,
      productId: product.id,
      productName: product.name,
      userId: userId,
      userName: userName,
      quantity: difference.abs(),
      type: difference > 0 ? OperationType.entree : OperationType.sortie,
      dateTime: DateTime.now(),
    );

    // Exécuter les deux opérations dans une transaction
    final batch = _firestore.batch();
    final productRef = _firestore.collection(_collection).doc(product.id);
    batch.update(productRef, updatedProduct.toMap());
    
    final operationRef = _firestore.collection('operations').doc(operation.id);
    batch.set(operationRef, operation.toMap());

    await batch.commit();
  }

  // Rechercher des produits par nom
  Stream<List<Product>> searchProducts(String query, {required String tenantId}) {
    return getAllProducts(tenantId: tenantId).map((products) => products
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()))
        .toList());
  }
} 