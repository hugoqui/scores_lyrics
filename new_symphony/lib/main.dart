import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/theme/app_theme.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/features/auth/ui/login_screen.dart';
import 'package:new_symphony/features/home/ui/home_screen.dart';
import 'package:new_symphony/data/repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  await _enableGlobalImmersiveMode();

  // Verificamos si hay una sesión válida antes de arrancar
  final bool loggedIn = getIt<AuthRepository>().isLoggedIn();
  
  runApp(
    ProviderScope(
      child: MyApp(startScreen: loggedIn ? const HomeScreen() : const LoginScreen()),
    ),
  );
}

Future<void> _enableGlobalImmersiveMode() {
  return SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

class MyApp extends StatefulWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableGlobalImmersiveMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enableGlobalImmersiveMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Symphony',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Usa la preferencia de tema del sistema
      home: widget.startScreen,
    );
  }
}
