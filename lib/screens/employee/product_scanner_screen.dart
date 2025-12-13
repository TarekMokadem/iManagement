import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/tenant_provider.dart';
import '../../services/product_service.dart';
import 'product_detail_screen.dart';

class ProductScannerScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ProductScannerScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandlingScan = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String rawValue) async {
    if (_isHandlingScan) return;
    setState(() => _isHandlingScan = true);

    try {
      final tenantId = context.read<TenantProvider>().tenantId;
      if (tenantId == null || tenantId.isEmpty) {
        throw Exception('Tenant introuvable pour cette session');
      }

      final productService = ProductService(tenantId: tenantId);
      final Product? product = await productService.getProductById(rawValue);

      if (!mounted) return;
      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produit introuvable pour le code: $rawValue')),
        );
        return;
      }

      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ProductDetailScreen(
            product: product,
            userId: widget.userId,
            userName: widget.userName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur scan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isHandlingScan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scanner un produit')),
        body: const Center(
          child: Text('Le scanner caméra n’est pas supporté sur Web pour le moment.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un produit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              final barcodes = capture.barcodes;
              final raw = barcodes.isNotEmpty ? barcodes.first.rawValue : null;
              if (raw == null || raw.isEmpty) return;
              await _handleBarcode(raw);
            },
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isHandlingScan
                            ? 'Ouverture du produit...'
                            : 'Scannez un QR/Code-barres contenant l’ID du produit.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


