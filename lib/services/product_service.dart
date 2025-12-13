import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/operation.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? tenantId;
  final String _collection = 'products';

  ProductService({this.tenantId});

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_collection).orderBy('lastUpdated', descending: true);
    if (tenantId != null && tenantId!.isNotEmpty) {
      query = query.where('tenantId', isEqualTo: tenantId);
    }
    return query;
  }

  // Obtenir tous les produits
  Stream<List<Product>> getAllProducts() {
    return _baseQuery().snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  // Obtenir les produits critiques
  Stream<List<Product>> getCriticalProducts() {
    return _baseQuery().snapshots().map((snapshot) => snapshot.docs
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

  Future<Product?> getProductById(String id) async {
    if (id.isEmpty) return null;
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final docTenant = data['tenantId'] as String?;
    if (tenantId != null && tenantId!.isNotEmpty && docTenant != null && docTenant != tenantId) {
      return null;
    }
    return Product.fromMap({...data, 'id': doc.id});
  }

  // Mettre à jour un produit
  Future<void> updateProduct(String id, Product product, {String? tenantId}) async {
    final data = product.toMap();
    final tenant = tenantId ?? this.tenantId;
    if (tenant != null && tenant.isNotEmpty) {
      data['tenantId'] = tenant;
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
  Stream<List<Product>> searchProducts(String query) {
    return getAllProducts().map((products) => products
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()))
        .toList());
  }
} 