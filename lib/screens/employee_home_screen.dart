import 'package:flutter/material.dart';
import 'employee/product_list_screen.dart';
import 'employee/critical_products_screen.dart';

class EmployeeHomeScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const EmployeeHomeScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bienvenue $userName'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Produits'),
              Tab(icon: Icon(Icons.warning), text: 'Critiques'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            ProductListScreen(userId: userId, userName: userName),
            CriticalProductsScreen(userId: userId, userName: userName),
          ],
        ),
      ),
    );
  }
} 