import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/employee_home_screen.dart';

class AdminGuard extends StatelessWidget {
  const AdminGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (!session.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
      return const SizedBox.shrink();
    }
    if (!session.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/employee');
        }
      });
      return const SizedBox.shrink();
    }
    final s = session.session!;
    return AdminHomeScreen(userId: s.userId, userName: s.userName);
  }
}

class EmployeeGuard extends StatelessWidget {
  const EmployeeGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (!session.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
      return const SizedBox.shrink();
    }
    final s = session.session!;
    return EmployeeHomeScreen(userId: s.userId, userName: s.userName);
  }
}


