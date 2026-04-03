import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/constants/app_styles.dart';
import 'package:new_symphony/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
    final authState = ref.watch(authProvider);

    // Escuchamos cambios en el estado para mostrar errores o navegar
    ref.listen(authProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al iniciar sesión: $error')),
          );
        },
        data: (_) {
          // Aquí iría la navegación a la pantalla principal después del éxito
        },
      );
    });

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bienvenido a Symphony',
              style: AppStyles.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingExtraLarge),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email o Usuario',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            authState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _onLogin,
                    child: const Text('Iniciar Sesión'),
                  ),
          ],
        ),
      ),
    );
  }
}