import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/tenant_provider.dart';
import 'repositories/firestore_operations_repository.dart';
import 'repositories/firestore_products_repository.dart';
import 'repositories/firestore_users_repository.dart';
import 'repositories/operations_repository.dart';
import 'repositories/products_repository.dart';
import 'repositories/users_repository.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/checkout_cancel_screen.dart';
import 'screens/checkout_success_screen.dart';
import 'screens/employee_home_screen.dart';
import 'screens/login_screen.dart';

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
      // localizationsDelegates: const [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('fr', ''),
      // ],
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/success': (context) => const CheckoutSuccessScreen(),
        '/cancel': (context) => const CheckoutCancelScreen(),
        '/employee': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return EmployeeHomeScreen(
            userId: args['userId']!,
            userName: args['userName']!,
          );
        },
        '/admin': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return AdminHomeScreen(
            userId: args['userId']!,
            userName: args['userName']!,
          );
        },
      },
      ),
    );
  }
} 