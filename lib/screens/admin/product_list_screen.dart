import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/products_repository.dart';
import '../../providers/tenant_provider.dart';
import '../../models/product.dart';

class ProductListScreen extends StatelessWidget {
  final String userId;
  final String userName;

  ProductListScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<ProductsRepository>(context, listen: false);
    final tenant = Provider.of<TenantProvider>(context, listen: false);
    return StreamBuilder<List<Product>>(
      stream: repository.watchProducts(tenantId: tenant.tenantId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!;
        
        if (products.isEmpty) {
          return const Center(child: Text('Aucun produit disponible'));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Dismissible(
              key: Key(product.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmation'),
                    content: Text('Voulez-vous vraiment supprimer ${product.name} ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                // TODO: Implémenter la suppression
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} supprimé'),
                    action: SnackBarAction(
                      label: 'Annuler',
                      onPressed: () {
                        // TODO: Implémenter l'annulation de la suppression
                      },
                    ),
                  ),
                );
              },
              child: Card(
                child: ListTile(
                  title: Text(product.name),
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
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // TODO: Implémenter la modification
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Modification à venir'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      if (product.isCritical)
                        const Icon(Icons.warning, color: Colors.red),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
} 