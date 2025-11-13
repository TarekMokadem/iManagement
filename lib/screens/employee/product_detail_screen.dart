import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/operation.dart';
import '../../models/product.dart';
import '../../providers/tenant_provider.dart';
import '../../services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String userId;
  final String userName;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _productService = ProductService();
  bool _isLoading = false;
  OperationType _selectedType = OperationType.entree;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '0';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _updateQuantity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final quantityChange = int.parse(_quantityController.text);
      final newQuantity = _selectedType == OperationType.entree
          ? widget.product.quantity + quantityChange
          : widget.product.quantity - quantityChange;

      if (newQuantity < 0) {
        throw Exception('La quantité ne peut pas être négative');
      }

      // Mettre à jour la quantité (l'opération sera créée dans ProductService)
      final tenantId = context.read<TenantProvider>().tenantId;
      if (tenantId == null || tenantId.isEmpty) {
        throw Exception('Tenant introuvable pour cette session');
      }

      await _productService.updateQuantity(
        widget.product,
        newQuantity,
        widget.userId,
        widget.userName,
        tenantId,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emplacement: ${widget.product.location}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (widget.product.isCritical)
                Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Stock critique ! Seuil: ${widget.product.criticalThreshold}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Quantité actuelle: ${widget.product.quantity}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              SegmentedButton<OperationType>(
                segments: const [
                  ButtonSegment<OperationType>(
                    value: OperationType.entree,
                    label: Text('Entrée'),
                  ),
                  ButtonSegment<OperationType>(
                    value: OperationType.sortie,
                    label: Text('Sortie'),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedType = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  final quantity = int.parse(value);
                  if (quantity <= 0) {
                    return 'La quantité doit être supérieure à 0';
                  }
                  if (_selectedType == OperationType.sortie && 
                      widget.product.quantity - quantity < 0) {
                    return 'La quantité ne peut pas être négative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateQuantity,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Mettre à jour la quantité'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 