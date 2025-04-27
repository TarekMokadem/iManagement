import 'package:flutter/material.dart';
import 'product_list_screen.dart';
import 'critical_products_screen.dart';
import '../login_screen.dart';

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
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
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
              Navigator.push(
                context,
                MaterialPageRoute(
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
              // TODO: Navigation vers le scanner
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité à venir'),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            'Produits critiques',
            Icons.warning,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
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