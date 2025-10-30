import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/tenant_provider.dart';
import 'screens/login_screen.dart';
import 'screens/employee_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';

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