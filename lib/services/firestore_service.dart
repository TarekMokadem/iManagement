import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get products => _firestore.collection('products');
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get logs => _firestore.collection('logs');

  // Méthodes pour les produits
  Future<void> addProduct(Map<String, dynamic> productData) async {
    await products.add(productData);
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    await products.doc(productId).update(productData);
  }

  Future<void> deleteProduct(String productId) async {
    await products.doc(productId).delete();
  }

  Stream<QuerySnapshot> getProducts() {
    return products.snapshots();
  }

  // Méthodes pour les utilisateurs
  Future<void> addUser(Map<String, dynamic> userData) async {
    await users.add(userData);
  }

  Future<QuerySnapshot> getUserByCode(String code) async {
    return await users.where('code', isEqualTo: code).get();
  }

  // Méthodes pour les logs
  Future<void> addLog(Map<String, dynamic> logData) async {
    await logs.add({
      ...logData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
} 