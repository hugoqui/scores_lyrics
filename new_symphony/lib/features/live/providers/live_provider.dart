import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/features/live/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';

class LiveState {
  final String status; // 'online', 'offline', 'reconnecting', 'fail'
  final String? currentSongTitle;
  final String lastHost;
  final List<String> liveSongList;
  final int currentIndex;
  final String? lastInstrumentPath;

  LiveState({
    required this.status,
    this.currentSongTitle,
    required this.lastHost,
    this.liveSongList = const [],
    this.currentIndex = 0,
    this.lastInstrumentPath,
  });

  LiveState copyWith({
    String? status,
    String? currentSongTitle,
    String? lastHost,
    List<String>? liveSongList,
    int? currentIndex,
    String? lastInstrumentPath,
  }) {
    return LiveState(
      status: status ?? this.status,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      lastHost: lastHost ?? this.lastHost,
      liveSongList: liveSongList ?? this.liveSongList,
      currentIndex: currentIndex ?? this.currentIndex,
      lastInstrumentPath: lastInstrumentPath ?? this.lastInstrumentPath,
    );
  }
}

class LiveNotifier extends StateNotifier<LiveState> {
  final SocketService _socketService;
  final SharedPreferences _prefs;
  final Dio _dio;
  StreamSubscription? _statusSub;
  StreamSubscription? _songSub;
  StreamSubscription? _listSub;

  LiveNotifier(this._socketService, this._prefs, this._dio)
      : super(LiveState(
          status: 'offline',
          lastHost: _prefs.getString('last_live_host') ?? '192.168.5.1:3014',
          lastInstrumentPath: _prefs.getString('last_live_instrument_path'),
        )) {
    _listenToSocket();
  }

  void _listenToSocket() {
    _statusSub = _socketService.statusStream.listen((status) {
      state = state.copyWith(status: status);
      if (status == 'online') {
        _fetchInitialData();
      }
    });

    _songSub = _socketService.songStream.listen((data) {
      // Forzamos el cast a Map para que el compilador sepa que los valores son dynamic
      if (data is Map<String, dynamic> || data is Map) {
        final mapData = data as Map;
        final title = mapData['title']?.toString() ?? '';
        final reference = mapData['reference']?.toString();
        _updateCurrentSong(title, reference: reference);
      } else {
        _updateCurrentSong(data.toString());
      }
    });

    _listSub = _socketService.listChangeStream.listen((_) {
      print('[live] socket:list_change currentSong=${state.currentSongTitle} currentIndex=${state.currentIndex} listSize=${state.liveSongList.length}');
      // Agregamos un delay de 300ms para permitir que el servidor 
      // termine de actualizar la lista antes de consultar el endpoint.
      Future.delayed(const Duration(milliseconds: 300), () {
        print('[live] list_change -> fetchSongList start');
        fetchSongList();
      });
    });
  }

  void connect(String host, String instrumentPath) {
    // Aseguramos que el host tenga el protocolo http
    String formattedHost = host.trim();
    if (!formattedHost.startsWith('http')) {
      formattedHost = 'http://$formattedHost';
    }
    
    _prefs.setString('last_live_host', host.trim());
    _prefs.setString('last_live_instrument_path', instrumentPath);
    
    state = state.copyWith(lastHost: host.trim(), lastInstrumentPath: instrumentPath);
    _socketService.connect(formattedHost);
  }

  Future<void> _fetchInitialData() async {
    await fetchSongList(isInitialFetch: true); // Indica que es la carga inicial
    // Solo consultamos lastSong si la lista del servidor no está vacía
    if (state.liveSongList.isNotEmpty) {
      await fetchLastSong();
    }
  }

  Future<void> fetchLastSong() async {
    try {
      final response = await _dio.get('${_getHostWithProtocol()}/api/lastSong');
      final data = response.data;
      if (data is Map && data['title'] != null) {
        _updateCurrentSong(data['title'].toString(), reference: data['reference']?.toString());
      } else if (data is String) {
        _updateCurrentSong(data);
      }
    } catch (_) {}
  }

  Future<void> fetchSongList({bool isInitialFetch = false}) async {
    try {
      print('[live] fetchSongList start initial=$isInitialFetch currentSong=${state.currentSongTitle} currentIndex=${state.currentIndex} localListSize=${state.liveSongList.length}');
      final response = await _dio.get('${_getHostWithProtocol()}/api/songList');
      final List<dynamic> data = response.data;
      
      // Extraemos los títulos originales (sin normalizar aquí para no perder el formato)
      final List<String> serverTitles = data
          .map((e) => (e is Map) ? e['title']?.toString() ?? '' : e.toString())
          .where((t) => t.isNotEmpty)
          .toList();

      List<String> newLiveSongList;
      if (isInitialFetch) {
        // En la carga inicial, la lista es *solo* lo que viene del servidor.
        // Esto limpia cualquier "canto zombie" de sesiones anteriores.
        newLiveSongList = serverTitles;
      } else if (serverTitles.isNotEmpty) {
        // Si el servidor envía una lista no vacía, esta es la fuente de verdad.
        // Mantenemos las canciones manuales *actuales* que no estén en la lista del servidor.
        final currentManualSongs = state.liveSongList.where((localTitle) =>
          !serverTitles.any((serverTitle) =>
            getIt<ScoreRepository>().normalizeTitle(serverTitle) == getIt<ScoreRepository>().normalizeTitle(localTitle))
        ).toList();
        newLiveSongList = [...serverTitles, ...currentManualSongs];
      } else {
        // Si el servidor envía una lista vacía (y no es la carga inicial),
        // significa que la lista debe estar vacía.
        newLiveSongList = [];
      }

      print('[live] fetchSongList response initial=$isInitialFetch serverListSize=${serverTitles.length} mergedListSize=${newLiveSongList.length} firstServer=${serverTitles.isNotEmpty ? serverTitles.first : 'null'} currentSong=${state.currentSongTitle}');

      // En updates de lista preservamos el canto actual; en carga inicial permitimos selección inicial.
      updateLiveSongList(
        newLiveSongList,
        preserveCurrentSong: !isInitialFetch,
      );
    } catch (e) {
      print('Error fetching song list: $e'); // Considerar un logger o feedback al usuario
    }
  }

  void addSongManual(String title) {
    if (!state.liveSongList.contains(title)) {
      // Usamos el helper para asegurar que la lista se actualice correctamente
      updateLiveSongList([...state.liveSongList, title]);
    }
    _updateCurrentSong(title);
  }

  // Método para actualizar la lista y recalcular el índice actual
  void updateLiveSongList(
    List<String> newTitles, {
    bool preserveCurrentSong = true,
  }) {
    final previousTitle = state.currentSongTitle;
    final previousIndex = state.currentIndex;

    // Aseguramos que los títulos sean únicos (basado en el título normalizado)
    final uniqueTitles = <String>[];
    final normalizedUniqueTitles = <String>{};
    final scoreRepo = getIt<ScoreRepository>();

    for (var title in newTitles) {
      final normalized = scoreRepo.normalizeTitle(title);
      if (normalizedUniqueTitles.add(normalized)) {
        uniqueTitles.add(title);
      }
    }

    String? newTitle = state.currentSongTitle;
    int newIndex = state.currentIndex;

    // En cambios de lista por socket, preservamos el canto actual.
    // Solo en carga inicial hacemos selección automática.
    if (newTitle != null) {
      int index = uniqueTitles.indexWhere(
        (t) => scoreRepo.normalizeTitle(t) == scoreRepo.normalizeTitle(newTitle!),
      );

      // Fallback por si el normalizado no coincide pero el texto sí coincide.
      if (index < 0) {
        final lowered = newTitle.trim().toLowerCase();
        index = uniqueTitles.indexWhere((t) => t.trim().toLowerCase() == lowered);
      }

      if (index >= 0) {
        newIndex = index;
        // Sincroniza el título con la representación exacta de la lista actual.
        newTitle = uniqueTitles[index];
      } else {
        if (!preserveCurrentSong) {
          // En carga inicial sí tomamos el primero disponible.
          newTitle = uniqueTitles.isNotEmpty ? uniqueTitles[0] : null;
          newIndex = 0;
        }
      }
    } else if (uniqueTitles.isNotEmpty && !preserveCurrentSong) {
      newTitle = uniqueTitles[0];
      newIndex = 0;
    }

    if (uniqueTitles.isEmpty) {
      newIndex = 0;
      if (!preserveCurrentSong) {
        newTitle = null;
      }
    } else if (newIndex >= uniqueTitles.length) {
      newIndex = uniqueTitles.length - 1;
    } else if (newIndex < 0) {
      newIndex = 0;
    }

    print('[live] updateLiveSongList preserve=$preserveCurrentSong prevSong=$previousTitle prevIndex=$previousIndex newSong=$newTitle newIndex=$newIndex oldListSize=${state.liveSongList.length} newListSize=${uniqueTitles.length}');

    state = state.copyWith(
      liveSongList: uniqueTitles, 
      currentIndex: newIndex,
      currentSongTitle: newTitle,
    );
  }

  void _updateCurrentSong(String title, {String? reference}) {
    final cleanTitle = title.trim();
    print('[live] _updateCurrentSong incoming title=$cleanTitle reference=$reference currentSong=${state.currentSongTitle} currentIndex=${state.currentIndex}');
    if (cleanTitle.isEmpty) return; // Evita el "canto vacío"
    if (reference != null && reference.trim().isNotEmpty) return;

    final scoreRepo = getIt<ScoreRepository>();
    final isKnownSong = scoreRepo.isValidSongTitle(cleanTitle) || 
                        state.liveSongList.any((t) => scoreRepo.normalizeTitle(t) == scoreRepo.normalizeTitle(cleanTitle));
    if (!isKnownSong) {
      print('[live] _updateCurrentSong ignored unknown title=$cleanTitle');
      return;
    }

    // Agregamos a la lista si no existe
    if (!state.liveSongList.any((t) => scoreRepo.normalizeTitle(t) == scoreRepo.normalizeTitle(cleanTitle))) {
      print('[live] _updateCurrentSong title missing in list, adding title=$cleanTitle');
      updateLiveSongList([...state.liveSongList, cleanTitle]);
    }

    // Buscamos el índice en la lista actualizada
    int index = state.liveSongList.indexWhere((t) => scoreRepo.normalizeTitle(t) == scoreRepo.normalizeTitle(cleanTitle));
    print('[live] _updateCurrentSong apply title=$cleanTitle resolvedIndex=$index');
    state = state.copyWith(
      currentSongTitle: cleanTitle,
      currentIndex: index >= 0 ? index : 0,
    );
  }

  void updateIndex(int index) {
    if (index >= 0 && index < state.liveSongList.length) {
      state = state.copyWith(
        currentIndex: index,
        currentSongTitle: state.liveSongList[index],
      );
    }
  }

  String _getHostWithProtocol() {
    String host = state.lastHost;
    if (!host.startsWith('http')) host = 'http://$host';
    return host;
  }

  void disconnect() {
    _socketService.disconnect();
    // Solo actualizamos el status, mantenemos la lista para que el usuario pueda seguir navegando
    state = state.copyWith(status: 'offline');
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _songSub?.cancel();
    _listSub?.cancel();
    super.dispose();
  }
}

final liveProvider = StateNotifierProvider<LiveNotifier, LiveState>((ref) {
  return LiveNotifier(
    getIt<SocketService>(),
    getIt<SharedPreferences>(),
    getIt<Dio>(),
  );
});