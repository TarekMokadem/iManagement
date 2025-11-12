import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/tenant_provider.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/employee_home_screen.dart';

class AdminGuard extends StatelessWidget {
  const AdminGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!session.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          if (ModalRoute.of(context)?.settings.name != '/login') {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!session.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          if (ModalRoute.of(context)?.settings.name != '/employee') {
            Navigator.pushReplacementNamed(context, '/employee');
          }
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = session.session!;
    context.read<TenantProvider>().setTenant(tenantId: s.tenantId);
    return AdminHomeScreen(userId: s.userId, userName: s.userName);
  }
}

class EmployeeGuard extends StatelessWidget {
  const EmployeeGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!session.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          if (ModalRoute.of(context)?.settings.name != '/login') {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = session.session!;
    context.read<TenantProvider>().setTenant(tenantId: s.tenantId);
    return EmployeeHomeScreen(userId: s.userId, userName: s.userName);
  }
}


