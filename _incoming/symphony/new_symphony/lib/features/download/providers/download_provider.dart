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

class DownloadState {
  final AsyncValue<List<DownloadableSong>> songs;
  final double downloadProgress; // 0.0 a 1.0
  final bool isDownloadingAll;

  DownloadState({
    required this.songs,
    this.downloadProgress = 0,
    this.isDownloadingAll = false,
  });

  DownloadState copyWith({
    AsyncValue<List<DownloadableSong>>? songs,
    double? downloadProgress,
    bool? isDownloadingAll,
  }) {
    return DownloadState(
      songs: songs ?? this.songs,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloadingAll: isDownloadingAll ?? this.isDownloadingAll,
    );
  }
}

/// Notificador global para la lista de archivos descargados
class DownloadedFilesNotifier extends StateNotifier<List<DownloadedFile>> {
  final ScoreRepository _repository;
  DownloadedFilesNotifier(this._repository) : super(_repository.downloadedFiles);

  void refresh() {
    state = [..._repository.downloadedFiles];
  }
}

final downloadedFilesProvider = StateNotifierProvider<DownloadedFilesNotifier, List<DownloadedFile>>((ref) {
  return DownloadedFilesNotifier(getIt<ScoreRepository>());
});

final downloadProvider = StateNotifierProvider.family<DownloadNotifier, DownloadState, String>((ref, instrument) {
  return DownloadNotifier(ref, getIt<ScoreRepository>(), instrument);
});

class DownloadNotifier extends StateNotifier<DownloadState> {
  final Ref _ref;
  final ScoreRepository _repository;
  final String instrument;
  List<DownloadableSong> _allSongs = []; // Cache para el listado completo
  String _lastQuery = '';

  DownloadNotifier(this._ref, this._repository, this.instrument)
      : super(DownloadState(songs: const AsyncValue.loading())) {
    loadSongs();
  }

  void _updateSongsState() {
    AsyncValue<List<DownloadableSong>> songsValue;
    if (_lastQuery.isEmpty) {
      songsValue = AsyncValue.data(_allSongs);
    } else {
      final filtered = _allSongs
          .where((s) => s.fileName.toLowerCase().contains(_lastQuery.toLowerCase()))
          .toList();
      songsValue = AsyncValue.data(filtered);
    }
    state = state.copyWith(songs: songsValue);
  }

  Future<void> loadSongs() async {
    state = state.copyWith(songs: const AsyncValue.loading());
    try {
      final remoteFiles = await _repository.fetchRemoteAvailableFiles(instrument);
      final localFiles = _repository.getDownloadedFilesByInstrument(instrument);
      
      final songs = remoteFiles.map((fileName) {
        final exists = localFiles.any((f) => f.fileName == fileName);
        return DownloadableSong(fileName: fileName, isDownloaded: exists);
      }).toList();
      
      _allSongs = songs;
      _updateSongsState();
    } catch (e, stack) {
      state = state.copyWith(songs: AsyncValue.error(e, stack));
    }
  }

  void filterSongs(String query) {
    _lastQuery = query;
    _updateSongsState();
  }

  Future<void> download(String fileName) async {
    _allSongs = _allSongs.map((s) => s.fileName == fileName ? s.copyWith(isDownloading: true) : s).toList();
    _updateSongsState();

    try {
      // 1. Descargar el archivo físico
      await _repository.downloadFile(fileName, instrument);
      
      // 2. Obtener la tonalidad de la API
      final chord = await _repository.getChordForSong(fileName, instrument);
      
      // 3. Registrar en la base de datos local
      final newFile = DownloadedFile(
        fileName: fileName,
        instrument: instrument,
        chord: chord,
      );
      _repository.addDownloadedFile(newFile);

      // Notificamos al estado global que hay un nuevo archivo
      _ref.read(downloadedFilesProvider.notifier).refresh();
      
      _allSongs = _allSongs.map((s) => 
        s.fileName == fileName ? s.copyWith(isDownloaded: true, isDownloading: false) : s
      ).toList();
      _updateSongsState();
    } catch (e) {
      _allSongs = _allSongs.map((s) => 
        s.fileName == fileName ? s.copyWith(isDownloading: false) : s
      ).toList();
      _updateSongsState();
    }
  }

  Future<void> downloadAll({bool forceRedownload = false}) async {
    state = state.copyWith(isDownloadingAll: true, downloadProgress: 0);

    try {
      if (forceRedownload) {
        // 1) Limpiar registros y archivos locales del instrumento para forzar redescarga completa.
        await _repository.clearDownloadedFilesByInstrument(instrument);
        _ref.read(downloadedFilesProvider.notifier).refresh();
      }

      // 2) Recargar lista remota/local con estado actualizado.
      await loadSongs();

      // 3) Elegir si bajamos solo faltantes o todos.
      final toDownload = forceRedownload
          ? _allSongs.where((s) => !s.isDownloading).toList()
          : _allSongs.where((s) => !s.isDownloaded && !s.isDownloading).toList();

      if (toDownload.isEmpty) {
        state = state.copyWith(isDownloadingAll: false, downloadProgress: 0);
        return;
      }

      final total = toDownload.length;
      int current = 0;

      for (final song in toDownload) {
        await download(song.fileName);
        current++;
        state = state.copyWith(downloadProgress: current / total);
      }
    } finally {
      state = state.copyWith(isDownloadingAll: false, downloadProgress: 0);
    }
  }
}