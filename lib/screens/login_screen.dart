import 'package:flutter/material.dart';

import 'tenant_login_screen.dart';

/// Écran legacy (ancienne connexion email/mdp).
/// Conservé pour compilation, mais l'app utilise désormais:
/// - `/tenant-login` (admins) + `/login` (users par code).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const TenantLoginScreen();
}