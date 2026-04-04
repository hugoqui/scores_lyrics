import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/constants/app_styles.dart';
import 'package:new_symphony/core/services/instruments_service.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/download/ui/instrument_selection_screen.dart';
import 'package:new_symphony/features/home/ui/live_screen.dart';
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
    final instruments = getIt<InstrumentsService>().instruments();
    Instrument? selectedInstrument;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          ),
          title: const Text('Conectarse a Transmisión'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('URL o IP del servidor:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '192.168.5.1:3014',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Instrumento para esta sesión:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<Instrument>(
                value: selectedInstrument,
                items: instruments.map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(i.name),
                )).toList(),
                onChanged: (val) => setState(() => selectedInstrument = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedInstrument == null ? null : () {
                final host = controller.text.trim();
                if (host.isNotEmpty) {
                  ref.read(liveProvider.notifier).connect(host);
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveScreen(instrument: selectedInstrument!),
                    ),
                  );
                }
              },
              child: const Text('Conectar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
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
                    Icon(icon, size: 28, color: AppColors.accent),
                    const SizedBox(width: AppDimensions.paddingLarge),
                    Text(title, style: AppStyles.headlineSmall.copyWith(fontSize: 16)),
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
                  Icon(icon, size: 32, color: AppColors.accent),
                const SizedBox(height: AppDimensions.spacingSmall),
                Text(title, style: AppStyles.headlineSmall.copyWith(fontSize: 14)),
              ],
            );
          },
        ),
      ),
    );
  }
}