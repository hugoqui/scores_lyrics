import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/features/auth/providers/auth_provider.dart';
import 'package:new_symphony/features/home/ui/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    
    final authState = ref.read(authProvider);
    _emailController = TextEditingController(text: authState.savedEmail);
    _passwordController = TextEditingController(text: authState.savedPassword);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    ref.read(authProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider.select((state) => state.loginStatus));

    ref.listen<AuthState>(authProvider, (previous, next) {
      next.loginStatus.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al iniciar sesión: $error')),
          );
        },
        data: (_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      );
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450), // Limita el ancho en landscape
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: AppDimensions.paddingExtraLarge),
                  
                  const Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email o Usuario',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.accent),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 40),
                  authState.isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _onLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('ENTRAR'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),      
    );
  }
}