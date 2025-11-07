import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/loading_indicator.dart';

class CriticalProductsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const CriticalProductsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<CriticalProductsScreen> createState() => _CriticalProductsScreenState();
}

class _CriticalProductsScreenState extends State<CriticalProductsScreen> {
  final ProductService productService = ProductService();
  String _searchQuery = '';
  String _sortBy = 'location';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits Critiques'),
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
              stream: productService.getAllProducts().map((products) {
                // Filtrer les produits critiques
                return products.where((product) => product.isCritical).toList();
              }),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const LoadingIndicator();
                }

                final criticalProducts = snapshot.data!;
                final filteredProducts = criticalProducts.where((product) {
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
                    child: Text('Aucun produit critique'),
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
                        leading: const Icon(
                          Icons.warning,
                          color: Colors.red,
                        ),
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
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Seuil critique: ${product.criticalThreshold}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditProductDialog(context, product),
                        ),
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

  Future<void> _showEditProductDialog(BuildContext context, Product product) async {
    final nameController = TextEditingController(text: product.name);
    final locationController = TextEditingController(text: product.location);
    final quantityController = TextEditingController(text: product.quantity.toString());
    final thresholdController = TextEditingController(text: product.criticalThreshold.toString());

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le produit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom du produit'),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Emplacement'),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: thresholdController,
                decoration: const InputDecoration(labelText: 'Seuil critique'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final updatedProduct = product.copyWith(
                name: nameController.text.trim(),
                location: locationController.text.trim(),
                quantity: int.tryParse(quantityController.text) ?? product.quantity,
                criticalThreshold: int.tryParse(thresholdController.text) ?? product.criticalThreshold,
                lastUpdated: DateTime.now(),
              );
              productService.updateProduct(updatedProduct.id, updatedProduct);
              Navigator.pop(context);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }
} 