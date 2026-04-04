import 'package:flutter/material.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/constants/app_styles.dart';
import 'package:new_symphony/features/download/ui/instrument_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      // Navegar a LiveComponent
                    },
                  ),            
                  _MenuCard(
                    title: 'Mis Listas',
                    icon: Icons.list,
                    onTap: () {
                      // Navegar a listas locales
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