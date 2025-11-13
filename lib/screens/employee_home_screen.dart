import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'employee/critical_products_screen.dart';
import 'employee/product_list_screen.dart';
import '../providers/session_provider.dart';
import '../providers/tenant_provider.dart';

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
              onPressed: () async {
                final session = context.read<SessionProvider>();
                final tenant = context.read<TenantProvider>();
                final navigator = Navigator.of(context);
                await session.logout();
                tenant.clearTenant();
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
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