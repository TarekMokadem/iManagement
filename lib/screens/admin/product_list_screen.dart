import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/tenant_provider.dart';
import '../../repositories/products_repository.dart';

class ProductListScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const ProductListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

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
                final tenantId = tenant.tenantId;
                if (tenantId == null || tenantId.isEmpty) return;
                () async {
                  await repository.deleteProduct(product.id, tenantId: tenantId);
                }();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} supprimé'),
                    action: SnackBarAction(
                      label: 'Annuler',
                      onPressed: () async {
                        final restored = product.copyWith(lastUpdated: DateTime.now());
                        await repository.upsertProduct(product.id, restored, tenantId: tenantId);
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
                          final tenantId = tenant.tenantId;
                          if (tenantId == null || tenantId.isEmpty) return;
                          _showEditDialog(context, repository, tenantId, product);
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

  void _showEditDialog(
    BuildContext context,
    ProductsRepository repository,
    String tenantId,
    Product product,
  ) {
    final nameController = TextEditingController(text: product.name);
    final locationController = TextEditingController(text: product.location);
    final qtyController = TextEditingController(text: product.quantity.toString());
    final criticalController = TextEditingController(text: product.criticalThreshold.toString());
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Modifier le produit'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Emplacement'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Emplacement requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: 'Quantité'),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Nombre invalide' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: criticalController,
                    decoration: const InputDecoration(labelText: 'Seuil critique'),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Nombre invalide' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                locationController.dispose();
                qtyController.dispose();
                criticalController.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final updated = product.copyWith(
                  name: nameController.text.trim(),
                  location: locationController.text.trim(),
                  quantity: int.parse(qtyController.text),
                  criticalThreshold: int.parse(criticalController.text),
                  lastUpdated: DateTime.now(),
                );
                await repository.updateProduct(product.id, updated, tenantId: tenantId);
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                }
                nameController.dispose();
                locationController.dispose();
                qtyController.dispose();
                criticalController.dispose();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
} 