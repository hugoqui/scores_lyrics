import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/theme/app_theme.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/features/auth/ui/login_screen.dart';
import 'package:new_symphony/features/home/ui/home_screen.dart';
import 'package:new_symphony/data/repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  // Verificamos si hay una sesión válida antes de arrancar
  final bool loggedIn = getIt<AuthRepository>().isLoggedIn();
  
  runApp(
    ProviderScope(
      child: MyApp(startScreen: loggedIn ? const HomeScreen() : const LoginScreen()),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Symphony',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Usa la preferencia de tema del sistema
      home: startScreen,
    );
  }
}
