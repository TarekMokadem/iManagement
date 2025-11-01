import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/operation.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // Obtenir tous les produits
  Stream<List<Product>> getAllProducts() {
    return _firestore
        .collection(_collection)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Obtenir les produits critiques
  Stream<List<Product>> getCriticalProducts() {
    return _firestore
        .collection(_collection)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
            .where((product) => product.isCritical)
            .toList());
  }

  // Ajouter un nouveau produit
  Future<void> addProduct(Product product) async {
    await _firestore.collection(_collection).add(product.toMap());
  }

  // Mettre à jour un produit
  Future<void> updateProduct(String id, Product product) async {
    await _firestore.collection(_collection).doc(id).update(product.toMap());
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