import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../providers/tenant_provider.dart';
import '../repositories/products_repository.dart';

class ProductListViewModel with ChangeNotifier {
  final ProductsRepository _repository;
  final TenantProvider _tenantProvider;

  ProductListViewModel({
    required ProductsRepository repository,
    required TenantProvider tenantProvider,
  })  : _repository = repository,
        _tenantProvider = tenantProvider;

  Stream<List<Product>> watchProducts() {
    final tenantId = _tenantProvider.tenantId;
    return _repository.watchProducts(tenantId: tenantId);
  }
}


