import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/download/providers/download_provider.dart';

class InstrumentGrid extends ConsumerWidget {
  final List<Instrument> instruments;
  final Function(Instrument) onInstrumentSelected;

  const InstrumentGrid({
    super.key,
    required this.instruments,
    required this.onInstrumentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos la lista global de archivos descargados
    final allDownloaded = ref.watch(downloadedFilesProvider);

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

        // Filtramos desde la lista reactiva del provider
        final int downloadedCount = allDownloaded
            .where((f) => f.instrument == instrument.path)
            .length;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingSmall,
            horizontal: AppDimensions.paddingMedium,
          ),
          leading: SvgPicture.asset(
            instrument.iconPath,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.accentLight // O AppColors.accent si prefieres dorado
                  : AppColors.primary, // Color original o primario en light
              BlendMode.srcIn,
            ),
            placeholderBuilder: (BuildContext context) =>
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
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.grey,
          ),
          onTap: () => onInstrumentSelected(instrument),
        );
      },
    );
  }
}
