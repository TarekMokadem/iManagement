import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/tenant_provider.dart';
import '../providers/session_provider.dart';
import '../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  int _remainingAttempts = 3;

  @override
  void initState() {
    super.initState();
    _loadRemainingAttempts();
  }

  Future<void> _loadRemainingAttempts() async {
    final attempts = await _authService.getRemainingAttempts();
    setState(() {
      _remainingAttempts = attempts;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.login(_codeController.text);
      if (mounted) {
        Provider.of<TenantProvider>(context, listen: false)
            .setTenant(tenantId: user.tenantId);
      }
      if (!mounted) return;

      // Créer une session (TTL 2h)
      final session = SessionData(
        userId: user.id,
        userName: user.name,
        tenantId: user.tenantId,
        isAdmin: user.isAdmin,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );
      if (mounted) {
        await context.read<SessionProvider>().login(session);
      }

      if (!mounted) return;
      await Navigator.pushReplacementNamed(context, user.isAdmin ? '/admin' : '/employee');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      await _loadRemainingAttempts();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (session.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final tenantId = session.session!.tenantId;
        context.read<TenantProvider>().setTenant(tenantId: tenantId);
        final target = session.isAdmin ? '/admin' : '/employee';
        if (ModalRoute.of(context)?.settings.name != target) {
          await Navigator.pushReplacementNamed(context, target);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory,
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),
                const Text(
                  'InvV1',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code d\'accès',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre code d\'accès';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_remainingAttempts < 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Il vous reste $_remainingAttempts tentative(s)',
                    style: TextStyle(
                      color: _remainingAttempts == 0 ? Colors.red : Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Comptes de démonstration:\n- admin : admin123\n- employé : emp123',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Se connecter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
} 