import 'package:flutter/material.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/data/models/instrument.dart';

class InstrumentGrid extends StatelessWidget {
  final List<Instrument> instruments;
  final Function(Instrument) onInstrumentSelected;

  const InstrumentGrid({
    super.key,
    required this.instruments,
    required this.onInstrumentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200, // Tamaño ideal para que quepan varios en horizontal
        mainAxisExtent: isPortrait ? 100 : 120, 
        crossAxisSpacing: AppDimensions.paddingMedium,
        mainAxisSpacing: AppDimensions.paddingMedium,
      ),
      itemCount: instruments.length,
      itemBuilder: (context, index) {
        final instrument = instruments[index];
        return Card(
          child: InkWell(
            onTap: () => onInstrumentSelected(instrument),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Usamos la imagen del asset con un color de tinte dorado si es necesario, 
                // o la imagen original si ya tiene color.
                Image.asset(
                  instrument.iconPath,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.music_note, color: AppColors.accent),
                ),
                const SizedBox(height: AppDimensions.spacingSmall),
                Text(
                  instrument.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
