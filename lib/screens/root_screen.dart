import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/tenant_provider.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _navigated = false;

  void _handleNavigation(SessionProvider session) {
    if (_navigated || session.isLoading) return;
    final isAuthenticated = session.isAuthenticated;
    final targetRoute =
        isAuthenticated ? (session.isAdmin ? '/admin' : '/employee') : '/login';

    if (isAuthenticated) {
      final tenantId = session.session!.tenantId;
      context.read<TenantProvider>().setTenant(tenantId: tenantId);
    } else {
      context.read<TenantProvider>().clearTenant();
    }

    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, targetRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    _handleNavigation(session);
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}


