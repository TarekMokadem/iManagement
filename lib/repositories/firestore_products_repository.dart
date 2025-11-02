import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import 'products_repository.dart';

class FirestoreProductsRepository implements ProductsRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'products';

  FirestoreProductsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Product>> watchProducts({String? tenantId}) {
    Query<Map<String, dynamic>> query = _firestore.collection(_collection);
    // Soft-tenantization: filtre si le champ existe; sinon, laisse passer (legacy).
    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.where('tenantId', isEqualTo: tenantId);
    }
    return query.orderBy('lastUpdated', descending: true).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }

  @override
  Future<void> addProduct(Product product, {required String tenantId}) async {
    final data = product.toMap();
    data['tenantId'] = tenantId;
    await _firestore.collection(_collection).add(data);
  }

  @override
  Future<void> updateProduct(String id, Product product, {required String tenantId}) async {
    final data = product.toMap();
    data['tenantId'] = tenantId;
    await _firestore.collection(_collection).doc(id).update(data);
  }

  @override
  Future<void> deleteProduct(String id, {required String tenantId}) async {
    // Optionnel: vérifier le tenant côté client; la règle Firestore fera foi.
    await _firestore.collection(_collection).doc(id).delete();
  }
}


