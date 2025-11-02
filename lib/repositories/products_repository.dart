import '../models/product.dart';

abstract class ProductsRepository {
  /// Observe all products for a given tenant. If [tenantId] is null or empty,
  /// the repository may return all products (legacy behavior).
  Stream<List<Product>> watchProducts({String? tenantId});

  Future<void> addProduct(Product product, {required String tenantId});
  Future<void> updateProduct(String id, Product product, {required String tenantId});
  Future<void> deleteProduct(String id, {required String tenantId});
}


