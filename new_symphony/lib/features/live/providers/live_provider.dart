import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/features/live/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveState {
  final String status; // 'online', 'offline', 'reconnecting', 'fail'
  final String? currentSongTitle;
  final String lastHost;

  LiveState({
    required this.status,
    this.currentSongTitle,
    required this.lastHost,
  });

  LiveState copyWith({
    String? status,
    String? currentSongTitle,
    String? lastHost,
  }) {
    return LiveState(
      status: status ?? this.status,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      lastHost: lastHost ?? this.lastHost,
    );
  }
}

class LiveNotifier extends StateNotifier<LiveState> {
  final SocketService _socketService;
  final SharedPreferences _prefs;
  StreamSubscription? _statusSub;
  StreamSubscription? _songSub;

  LiveNotifier(this._socketService, this._prefs)
      : super(LiveState(
          status: 'offline',
          lastHost: _prefs.getString('last_live_host') ?? '192.168.5.1:3014',
        )) {
    _listenToSocket();
  }

  void _listenToSocket() {
    _statusSub = _socketService.statusStream.listen((status) {
      state = state.copyWith(status: status);
    });

    _songSub = _socketService.songStream.listen((title) {
      state = state.copyWith(currentSongTitle: title);
    });
  }

  void connect(String host) {
    // Aseguramos que el host tenga el protocolo http
    String formattedHost = host.trim();
    if (!formattedHost.startsWith('http')) {
      formattedHost = 'http://$formattedHost';
    }
    
    _prefs.setString('last_live_host', host.trim());
    state = state.copyWith(lastHost: host.trim());
    _socketService.connect(formattedHost);
  }

  void disconnect() {
    _socketService.disconnect();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _songSub?.cancel();
    super.dispose();
  }
}

final liveProvider = StateNotifierProvider<LiveNotifier, LiveState>((ref) {
  return LiveNotifier(
    getIt<SocketService>(),
    getIt<SharedPreferences>(),
  );
});