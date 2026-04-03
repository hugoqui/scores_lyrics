import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/models/downloaded_file.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';

class DownloadableSong {
  final String fileName;
  final bool isDownloaded;
  final bool isDownloading;

  DownloadableSong({
    required this.fileName,
    this.isDownloaded = false,
    this.isDownloading = false,
  });

  DownloadableSong copyWith({bool? isDownloaded, bool? isDownloading}) {
    return DownloadableSong(
      fileName: fileName,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }
}

final downloadProvider = StateNotifierProvider.family<DownloadNotifier, AsyncValue<List<DownloadableSong>>, String>((ref, instrument) {
  return DownloadNotifier(getIt<ScoreRepository>(), instrument);
});

class DownloadNotifier extends StateNotifier<AsyncValue<List<DownloadableSong>>> {
  final ScoreRepository _repository;
  final String instrument;

  DownloadNotifier(this._repository, this.instrument) : super(const AsyncValue.loading()) {
    loadSongs();
  }

  Future<void> loadSongs() async {
    state = const AsyncValue.loading();
    try {
      final remoteFiles = await _repository.fetchRemoteAvailableFiles(instrument);
      final localFiles = _repository.getDownloadedFilesByInstrument(instrument);
      
      final songs = remoteFiles.map((fileName) {
        final exists = localFiles.any((f) => f.fileName == fileName);
        return DownloadableSong(fileName: fileName, isDownloaded: exists);
      }).toList();
      
      state = AsyncValue.data(songs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> download(String fileName) async {
    final currentSongs = state.value ?? [];
    state = AsyncValue.data(currentSongs.map((s) => s.fileName == fileName ? s.copyWith(isDownloading: true) : s).toList());

    try {
      // 1. Descargar el archivo físico
      await _repository.downloadFile(fileName, instrument);
      
      // 2. Obtener la tonalidad de la API
      final chord = await _repository.getChordForSong(fileName, instrument);
      
      // 3. Registrar en la base de datos local
      // Nota: Aquí asumimos que ScoreRepository tendrá un método para añadir a la lista. 
      // Por ahora actualizamos el estado visual.
      
      state = AsyncValue.data(state.value!.map((s) => 
        s.fileName == fileName ? s.copyWith(isDownloaded: true, isDownloading: false) : s
      ).toList());
    } catch (e) {
      state = AsyncValue.data(state.value!.map((s) => 
        s.fileName == fileName ? s.copyWith(isDownloading: false) : s
      ).toList());
    }
  }
}