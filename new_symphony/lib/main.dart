import 'package:flutter/material.dart';
import 'package:new_symphony/core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Symphony App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Usa la preferencia de tema del sistema
      home: const PlaceholderHomePage(), // Una página temporal
    );
  }
}

class PlaceholderHomePage extends StatelessWidget {
  const PlaceholderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Symphony App - Home'),
      ),
      body: Center(
        child: Text(
          'Bienvenido a Symphony App!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
