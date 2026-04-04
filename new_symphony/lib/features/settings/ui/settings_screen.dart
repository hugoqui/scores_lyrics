import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = getIt<SharedPreferences>();
    // Intentamos obtener el host guardado, de lo contrario usamos el de producción por defecto
    final currentHost = prefs.getString('api_host') ?? 'https://api.iglesiacristianabelen.com/api';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              children: [
                ListTile(
                  title: const Text('URL del Servidor API'),
                  subtitle: Text(currentHost),
                  leading: const Icon(Icons.dns),
                  onTap: () => _showHostDialog(context, currentHost),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Cerrar Sesión'),
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  onTap: () => _showLogoutConfirmation(context),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            child: Text(
              'Versión 1.0.0',
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showHostDialog(BuildContext context, String currentHost) {
    final controller = TextEditingController(text: currentHost);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Host'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final newHost = controller.text.trim();
              if (newHost.isNotEmpty) {
                getIt<SharedPreferences>().setString('api_host', newHost);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Host actualizado. Reinicie la app para aplicar cambios.')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              getIt<SharedPreferences>().remove('token');
              // Navegamos al inicio (Login) eliminando el historial de navegación
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
