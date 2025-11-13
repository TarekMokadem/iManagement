import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/tenant_provider.dart';
import 'employee/critical_products_screen.dart';
import 'employee/product_list_screen.dart';

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
                final sessionProvider = context.read<SessionProvider>();
                final tenantProvider = context.read<TenantProvider>();
                final navigator = Navigator.of(context);
                
                await sessionProvider.logout();
                tenantProvider.clearTenant();
                
                if (context.mounted) {
                  navigator.pushReplacementNamed('/login');
                }
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