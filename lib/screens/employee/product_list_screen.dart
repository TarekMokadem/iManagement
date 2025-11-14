import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/tenant_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/loading_indicator.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ProductListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final ProductService productService;
  String _searchQuery = '';
  String _sortBy = 'location';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final tenantId = context.watch<TenantProvider>().tenantId;
    productService = ProductService(tenantId: tenantId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Produits'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (String value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'name',
                child: Text('Trier par nom'),
              ),
              const PopupMenuItem<String>(
                value: 'location',
                child: Text('Trier par emplacement'),
              ),
              const PopupMenuItem<String>(
                value: 'quantity',
                child: Text('Trier par quantité'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher un produit',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: productService.getAllProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const LoadingIndicator();
                }

                final products = snapshot.data!;
                final filteredProducts = products.where((product) {
                  if (_searchQuery.isEmpty) return true;
                  return product.name.toLowerCase().contains(_searchQuery) ||
                      product.location.toLowerCase().contains(_searchQuery);
                }).toList();

                // Appliquer le tri
                filteredProducts.sort((a, b) {
                  int result;
                  switch (_sortBy) {
                    case 'name':
                      result = a.name.compareTo(b.name);
                      break;
                    case 'location':
                      result = a.location.compareTo(b.location);
                      break;
                    case 'quantity':
                      result = a.quantity.compareTo(b.quantity);
                      break;
                    default:
                      result = 0;
                  }
                  return _sortAscending ? result : -result;
                });

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('Aucun produit trouvé'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        leading: product.isCritical
                            ? const Icon(
                                Icons.warning,
                                color: Colors.red,
                              )
                            : null,
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Emplacement: ${product.location}'),
                            Text(
                              'Quantité: ${product.quantity}',
                              style: TextStyle(
                                color: product.isCritical ? Colors.red : null,
                                fontWeight: product.isCritical ? FontWeight.bold : null,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => ProductDetailScreen(
                                product: product,
                                userId: widget.userId,
                                userName: widget.userName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 