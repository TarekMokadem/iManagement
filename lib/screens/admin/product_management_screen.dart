import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/tenant_provider.dart';
import '../../repositories/products_repository.dart';
import '../../widgets/action_button.dart';

class ProductManagementScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ProductManagementScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Produits'),
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
              const PopupMenuItem<String>(
                value: 'critical',
                child: Text('Trier par statut critique'),
              ),
            ],
          ),
          ActionButton(
            icon: Icons.add,
            onPressed: () => _showAddProductDialog(context),
            tooltip: 'Ajouter un produit',
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
                suffixIcon: _searchQuery.isNotEmpty
                    ? ActionButton(
                        icon: Icons.clear,
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        tooltip: 'Effacer la recherche',
                      )
                    : null,
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
              stream: Provider.of<ProductsRepository>(context, listen: false)
                  .watchProducts(tenantId: Provider.of<TenantProvider>(context, listen: false).tenantId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement des produits\n${snapshot.error}',
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
                        Text('Chargement des produits...'),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!;
                final filteredProducts = products.where((product) {
                  return product.name.toLowerCase().contains(_searchQuery) ||
                      product.location.toLowerCase().contains(_searchQuery);
                }).toList();

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
                    case 'critical':
                      result = (a.isCritical ? 1 : 0).compareTo(b.isCritical ? 1 : 0);
                      break;
                    default:
                      result = 0;
                  }
                  return _sortAscending ? result : -result;
                });

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
                              style: product.isCritical
                                  ? const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    )
                                  : null,
                            ),
                            Text('Seuil critique: ${product.criticalThreshold}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ActionButton(
                              icon: Icons.edit,
                              onPressed: () => _showEditProductDialog(context, product),
                              tooltip: 'Modifier',
                              isSecondary: true,
                            ),
                            ActionButton(
                              icon: Icons.delete,
                              onPressed: () => _showDeleteConfirmationDialog(context, product),
                              tooltip: 'Supprimer',
                              color: Colors.red,
                              isSecondary: true,
                            ),
                          ],
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

  Future<void> _showAddProductDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final quantityController = TextEditingController();
    final thresholdController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un produit'),
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
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final productsRepo = Provider.of<ProductsRepository>(context, listen: false);
              final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
              final tenantId = tenantProvider.tenantId;
              if (tenantId == null || tenantId.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Tenant introuvable. Veuillez vous reconnecter.')),
                );
                return;
              }

              final maxProducts = tenantProvider.maxProducts;
              if (maxProducts != null) {
                final currentCount = await productsRepo.countProducts(tenantId: tenantId);
                if (currentCount >= maxProducts) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Quota de produits atteint pour votre abonnement. Passez au plan supérieur pour ajouter davantage de produits.'),
                    ),
                  );
                  return;
                }
              }

              final product = Product(
                id: '',
                name: nameController.text.trim(),
                location: locationController.text.trim(),
                quantity: int.tryParse(quantityController.text) ?? 0,
                criticalThreshold: int.tryParse(thresholdController.text) ?? 0,
                lastUpdated: DateTime.now(),
              );
              await productsRepo.addProduct(product, tenantId: tenantId);
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text('${product.name} ajouté avec succès')),
              );
            },
            child: const Text('Ajouter'),
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
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final updatedProduct = product.copyWith(
                name: nameController.text.trim(),
                location: locationController.text.trim(),
                quantity: int.tryParse(quantityController.text) ?? product.quantity,
                criticalThreshold: int.tryParse(thresholdController.text) ?? product.criticalThreshold,
                lastUpdated: DateTime.now(),
              );
              final repo = Provider.of<ProductsRepository>(context, listen: false);
              final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
              final tenantId = tenantProvider.tenantId;
              if (tenantId == null || tenantId.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Tenant introuvable. Veuillez vous reconnecter.')),
                );
                return;
              }
              await repo.updateProduct(updatedProduct.id, updatedProduct, tenantId: tenantId);
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text('${updatedProduct.name} mis à jour')),
              );
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, Product product) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${product.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final repo = Provider.of<ProductsRepository>(context, listen: false);
              final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
              final tenantId = tenantProvider.tenantId;
              if (tenantId == null || tenantId.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Tenant introuvable. Veuillez vous reconnecter.')),
                );
                return;
              }
              await repo.deleteProduct(product.id, tenantId: tenantId);
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text('${product.name} supprimé')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
} 