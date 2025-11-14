import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/tenant_provider.dart';
import '../../services/product_service.dart';

class CriticalProductsScreen extends StatelessWidget {
  final String userId;
  final String userName;
  late final ProductService _productService;

  CriticalProductsScreen({
    super.key,
    required this.userId,
    required this.userName,
  }) : _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    final tenantId = context.watch<TenantProvider>().tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits critiques'),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productService.getCriticalProducts(tenantId: tenantId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement des produits critiques\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des produits critiques...'),
                ],
              ),
            );
          }

          final products = snapshot.data!;

          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Aucun produit critique pour le moment'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(product.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emplacement: ${product.location}'),
                      Text(
                        'Quantité: ${product.quantity}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Seuil critique: ${product.criticalThreshold}'),
                    ],
                  ),
                  trailing: const Tooltip(
                    message: 'Stock critique',
                    child: Icon(Icons.warning, color: Colors.red),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Détails du produit ${product.name}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 