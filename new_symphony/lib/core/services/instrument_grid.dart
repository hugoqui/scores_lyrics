import 'package:flutter/material.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';

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
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: instruments.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 72, // Alinea el divisor con el inicio del texto
        color: AppColors.lightGrey,
      ),
      itemBuilder: (context, index) {
        final instrument = instruments[index];
        // Obtenemos el conteo real de archivos descargados para este instrumento
        final int downloadedCount = getIt<ScoreRepository>()
            .getDownloadedFilesByInstrument(instrument.path)
            .length;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingSmall,
            horizontal: AppDimensions.paddingMedium,
          ),
          leading: Image.asset(
            instrument.iconPath,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.music_note, color: AppColors.accent, size: 32),
          ),
          title: Text(
            instrument.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            '$downloadedCount partituras descargadas',
            style: const TextStyle(color: AppColors.grey, fontSize: 13),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grey),
          onTap: () => onInstrumentSelected(instrument),
        );
      },
    );
  }
}