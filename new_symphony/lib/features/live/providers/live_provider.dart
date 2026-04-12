import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/features/live/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    _songSub = _socketService.songStream.listen((title) {
      _updateCurrentSong(title);
    });

    _listSub = _socketService.listChangeStream.listen((_) {
      fetchSongList();
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
    await fetchSongList();
    await fetchLastSong();
  }

  Future<void> fetchLastSong() async {
    try {
      final response = await _dio.get('${_getHostWithProtocol()}/api/lastSong');
      final data = response.data;
      if (data is Map && data['title'] != null) {
        _updateCurrentSong(data['title'].toString());
      } else if (data is String) {
        _updateCurrentSong(data);
      }
    } catch (_) {}
  }

  Future<void> fetchSongList() async {
    try {
      final response = await _dio.get('${_getHostWithProtocol()}/api/songList');
      final List<dynamic> data = response.data;
      
      // Extraemos solo el título de cada objeto del servidor
      final List<String> serverTitles = data.map((e) {
        if (e is Map) return e['title']?.toString() ?? '';
        return e.toString();
      }).where((t) => t.isNotEmpty).toList();
      
      // Mantenemos los que el usuario agregó a mano si no están en la lista del servidor
      // Usamos una comparación insensible a mayúsculas/espacios para evitar duplicados
      final manualSongs = state.liveSongList.where((localTitle) => 
        !serverTitles.any((serverTitle) => 
          serverTitle.toLowerCase().trim() == localTitle.toLowerCase().trim())
      ).toList();
      
      state = state.copyWith(liveSongList: [...serverTitles, ...manualSongs]);
    } catch (_) {}
  }

  void addSongManual(String title) {
    if (!state.liveSongList.contains(title)) {
      state = state.copyWith(liveSongList: [...state.liveSongList, title]);
    }
    _updateCurrentSong(title);
  }

  void updateLiveSongList(List<String> titles) {
    state = state.copyWith(liveSongList: titles);
    // Si el canto actual ya no está en la nueva lista, intentamos mantener la posición o ir al inicio
    if (state.currentSongTitle != null) {
      int index = titles.indexOf(state.currentSongTitle!);
      state = state.copyWith(currentIndex: index >= 0 ? index : 0);
    }
  }

  void _updateCurrentSong(String title) {
    final cleanTitle = title.trim();
    int index = state.liveSongList.indexWhere((t) => t.toLowerCase() == cleanTitle.toLowerCase());
    
    if (index == -1) {
      // Si el canto no está en la lista, lo agregamos al final para poder navegar a él
      final newList = [...state.liveSongList, cleanTitle];
      state = state.copyWith(
        liveSongList: newList,
        currentSongTitle: cleanTitle,
        currentIndex: newList.length - 1,
      );
    } else {
      state = state.copyWith(
        currentSongTitle: cleanTitle,
        currentIndex: index,
      );
    }
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