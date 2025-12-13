import 'package:flutter/material.dart';

import '../login_screen.dart';
import 'critical_products_screen.dart';
import 'product_list_screen.dart';
import 'product_scanner_screen.dart';

class EmployeeHomeScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const EmployeeHomeScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des stocks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement<void, void>(
                MaterialPageRoute<void>(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            'Liste des produits',
            Icons.list_alt,
            () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => ProductListScreen(
                    userId: userId,
                    userName: userName,
                  ),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            'Scanner un produit',
            Icons.qr_code_scanner,
            () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => ProductScannerScreen(
                    userId: userId,
                    userName: userName,
                  ),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            'Produits critiques',
            Icons.warning,
            () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => CriticalProductsScreen(
                    userId: userId,
                    userName: userName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
} 