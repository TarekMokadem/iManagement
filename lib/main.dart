import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/session_provider.dart';
import 'providers/tenant_provider.dart';
import 'repositories/firestore_operations_repository.dart';
import 'repositories/firestore_products_repository.dart';
import 'repositories/firestore_users_repository.dart';
import 'repositories/operations_repository.dart';
import 'repositories/products_repository.dart';
import 'repositories/users_repository.dart';
import 'screens/checkout_cancel_screen.dart';
import 'screens/checkout_success_screen.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/onboarding/onboarding_wizard_screen.dart';
import 'screens/root_screen.dart';
import 'screens/signup/signup_screen.dart';
import 'screens/tenant_dashboard_screen.dart';
import 'screens/tenant_login_screen.dart';
import 'screens/user_login_screen.dart';
import 'widgets/guards.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TenantProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        // Repositories
        Provider<ProductsRepository>(create: (_) => FirestoreProductsRepository()),
        Provider<UsersRepository>(create: (_) => FirestoreUsersRepository()),
        Provider<OperationsRepository>(create: (_) => FirestoreOperationsRepository()),
      ],
      child: MaterialApp(
      title: 'InvV1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        // Connexions
        '/tenant-login': (context) => const TenantLoginScreen(),
        '/tenant-dashboard': (context) => TenantDashboardScreen(),
        '/login': (context) => const UserLoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/onboarding': (context) => const OnboardingWizardScreen(),
        '/app': (context) => const RootScreen(),
        '/success': (context) => const CheckoutSuccessScreen(),
        '/cancel': (context) => const CheckoutCancelScreen(),
        '/employee': (context) => const EmployeeGuard(),
        '/admin': (context) => const AdminGuard(),
      },
      ),
    );
  }
} 