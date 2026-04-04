import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/constants/app_styles.dart';
import 'package:new_symphony/features/download/ui/instrument_selection_screen.dart';
import 'package:new_symphony/features/live/providers/live_provider.dart';
import 'package:new_symphony/features/my_lists/ui/my_lists_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    // Configuramos la altura fija según la orientación para que no se vea "enorme"
    // En vertical (lista) 80px es elegante. En horizontal (cuadrícula) 140px funciona bien.
    final double itemHeight = isPortrait ? 80 : 140;

    // Si el ancho de la columna supera los 500px, el Grid creará automáticamente otra columna.
    // Esto actúa como el "Wrap" que mencionabas pero manteniendo alineación.
    const double maxColumnWidth = 500;

    final liveState = ref.watch(liveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symphony App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navegar a ajustes
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppDimensions.paddingExtraLarge),
          Image.asset(
            'assets/images/logo.png',
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: GridView(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxColumnWidth,
                  mainAxisExtent: itemHeight,
                  crossAxisSpacing: AppDimensions.paddingMedium,
                  mainAxisSpacing: AppDimensions.paddingMedium,
                ),
                children: [
                  _MenuCard(
                    title: 'Conectarse a Transmisión',
                    subtitle: _getStatusText(liveState.status),
                    statusColor: _getStatusColor(liveState.status),
                    icon: Icons.wifi_tethering,
                    onTap: () {
                      _showConnectDialog(context, ref);
                    },
                  ),            
                  _MenuCard(
                    title: 'Mis Listas',
                    icon: Icons.list,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyListsScreen()),
                      );
                    },
                  ),
                  _MenuCard(
                    title: 'Practicar',
                    icon: Icons.music_note,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InstrumentSelectionScreen(isPractice: true)),
                      );
                    },
                  ),
                  _MenuCard(
                    title: 'Descargar',
                    icon: Icons.download,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InstrumentSelectionScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectDialog(BuildContext context, WidgetRef ref) {
    final lastHost = ref.read(liveProvider).lastHost;
    final controller = TextEditingController(text: lastHost);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        title: const Text('Conectarse a Transmisión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingrese la URL o IP del servidor:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '192.168.5.1:3014',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final host = controller.text.trim();
              if (host.isNotEmpty) {
                ref.read(liveProvider.notifier).connect(host);
                Navigator.pop(context);
                // En el futuro, aquí navegaremos a la pantalla de Live
              }
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'online': return 'Conectado';
      case 'reconnecting': return 'Reconectando...';
      case 'fail': return 'Error de conexión';
      case 'offline': return 'Desconectado';
      default: return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online': return AppColors.accent;
      case 'reconnecting': return AppColors.accent.withOpacity(0.5);
      case 'fail': return AppColors.error;
      default: return AppColors.grey;
    }
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? statusColor;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    this.subtitle,
    this.statusColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card( // El estilo ahora viene del CardTheme definido en AppTheme
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Si la tarjeta es ancha (más de 350px), diseño de fila (List-style)
            // Si es más angosta (cuadrícula), diseño de columna (Grid-style)
            if (constraints.maxWidth > 350) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
                child: Row(
                  children: [
                    Icon(icon, size: 28, color: statusColor ?? AppColors.accent),
                    const SizedBox(width: AppDimensions.paddingLarge),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppStyles.headlineSmall.copyWith(fontSize: 16)),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor ?? AppColors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, color: AppColors.grey, size: 16),
                  ],
                ),
              );
            }

            // Diseño para Grid (Landscape o Tablet)
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Icon(icon, size: 32, color: statusColor ?? AppColors.accent),
                const SizedBox(height: AppDimensions.spacingSmall),
                Text(title, style: AppStyles.headlineSmall.copyWith(fontSize: 14)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor ?? AppColors.grey,
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}