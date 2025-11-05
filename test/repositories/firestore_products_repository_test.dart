import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_invv1/repositories/firestore_products_repository.dart';
import 'package:app_invv1/repositories/products_repository.dart';
import 'package:app_invv1/models/product.dart';

void main() {
  group('FirestoreProductsRepository', () {
    late FakeFirebaseFirestore fake;
    late ProductsRepository repo;

    setUp(() {
      fake = FakeFirebaseFirestore();
      repo = FirestoreProductsRepository(firestore: fake);
    });

    test('watchProducts filtre par tenantId', () async {
      // Pré-peupler des docs
      await fake.collection('products').add({
        'name': 'P1',
        'location': 'A',
        'quantity': 1,
        'criticalThreshold': 2,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
        'tenantId': 't1',
      });
      await fake.collection('products').add({
        'name': 'P2',
        'location': 'B',
        'quantity': 5,
        'criticalThreshold': 3,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
        'tenantId': 't2',
      });

      final stream = repo.watchProducts(tenantId: 't1');
      final list = await stream.first;
      expect(list.length, 1);
      expect(list.first.name, 'P1');
    });

    test('addProduct écrit tenantId', () async {
      final now = DateTime.now();
      final p = Product(
        id: '',
        name: 'P3',
        location: 'C',
        quantity: 10,
        criticalThreshold: 1,
        lastUpdated: now,
      );

      await repo.addProduct(p, tenantId: 'tX');

      final snap = await fake.collection('products').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['tenantId'], 'tX');
    });

    test('updateProduct conserve tenantId demandé', () async {
      final doc = await fake.collection('products').add({
        'name': 'Old',
        'location': 'Z',
        'quantity': 0,
        'criticalThreshold': 0,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
        'tenantId': 't1',
      });

      final updated = Product(
        id: doc.id,
        name: 'New',
        location: 'Z',
        quantity: 2,
        criticalThreshold: 1,
        lastUpdated: DateTime.now(),
      );

      await repo.updateProduct(doc.id, updated, tenantId: 't1');

      final after = await fake.collection('products').doc(doc.id).get();
      expect(after.data()!['name'], 'New');
      expect(after.data()!['tenantId'], 't1');
    });
  });
}


