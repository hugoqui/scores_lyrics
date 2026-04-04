import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';

class PracticeSong {
  final String title;
  final String melodyFileName;
  final String? arrangementFileName;
  final String instrument;
  final bool hasMelodyDownloaded;
  final bool hasArrangementDownloaded;

  PracticeSong({
    required this.title,
    required this.melodyFileName,
    this.arrangementFileName,
    required this.instrument,
    this.hasMelodyDownloaded = false,
    this.hasArrangementDownloaded = false,
  });
}

final practiceSongsProvider = StateNotifierProvider.family<PracticeNotifier, AsyncValue<List<PracticeSong>>, String>((ref, instrument) {
  return PracticeNotifier(getIt<ScoreRepository>(), instrument);
});

class PracticeNotifier extends StateNotifier<AsyncValue<List<PracticeSong>>> {
  final ScoreRepository _repository;
  final String instrument;
  List<PracticeSong> _allSongs = [];
  String _query = '';

  PracticeNotifier(this._repository, this.instrument) : super(const AsyncValue.loading()) {
    loadLibrary();
  }

  void filterSongs(String query) {
    _query = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      state = AsyncValue.data(_allSongs);
    } else {
      final filtered = _allSongs.where((s) => s.title.toLowerCase().contains(_query.toLowerCase())).toList();
      state = AsyncValue.data(filtered);
    }
  }

  void loadLibrary() {
    try {
      final allFiles = _repository.getDownloadedFilesByInstrument(instrument);
      
      // Mapa para agrupar por nombre base del canto
      // Clave: nombre_base (sin .png y sin _instrumento)
      final Map<String, PracticeSong> songsMap = {};

      for (var file in allFiles) {
        final fileName = file.fileName;
        final isArrangement = fileName.contains('_$instrument');
        
        // Obtener el nombre base (ej: "abre_mis_ojos")
        String baseName = fileName.replaceAll('.png', '');
        if (isArrangement) {
          baseName = baseName.replaceFirst('_$instrument', '');
        }

        final current = songsMap[baseName];
        
        if (current == null) {
          songsMap[baseName] = PracticeSong(
            title: baseName
                .replaceAll('_', ' ')
                .split(' ')
                .where((word) => word.isNotEmpty)
                .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
                .join(' '),
            melodyFileName: '$baseName.png',
            arrangementFileName: isArrangement ? fileName : null,
            instrument: instrument,
            hasMelodyDownloaded: !isArrangement,
            hasArrangementDownloaded: isArrangement,
          );
        } else {
          // Actualizar el existente si encontramos la otra "mitad" (melodía o arreglo)
          songsMap[baseName] = PracticeSong(
            title: current.title,
            melodyFileName: current.melodyFileName,
            arrangementFileName: isArrangement ? fileName : current.arrangementFileName,
            instrument: instrument,
            hasMelodyDownloaded: current.hasMelodyDownloaded || !isArrangement,
            hasArrangementDownloaded: current.hasArrangementDownloaded || isArrangement,
          );
        }
      }

      // Convertimos a lista y ordenamos alfabéticamente
      _allSongs = songsMap.values.toList()..sort((a, b) => a.title.compareTo(b.title));
      _applyFilter();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}