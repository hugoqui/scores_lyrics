import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
import 'dart:async';

class ScoreState {
  final bool isArrangementMode;
  final bool isAudioArrangement;
  final bool isUiVisible;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;
  final bool isLoopEnabled;
  final double playSpeed;

  ScoreState({
    this.isArrangementMode = true,
    this.isAudioArrangement = true,
    this.isUiVisible = true,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isLoading = false,
    this.isLoopEnabled = false,
    this.playSpeed = 1.0,
  });

  ScoreState copyWith({
    bool? isArrangementMode,
    bool? isAudioArrangement,
    bool? isUiVisible,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isLoading,
    bool? isLoopEnabled,
    double? playSpeed,
  }) {
    return ScoreState(
      isArrangementMode: isArrangementMode ?? this.isArrangementMode,
      isAudioArrangement: isAudioArrangement ?? this.isAudioArrangement,
      isUiVisible: isUiVisible ?? this.isUiVisible,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      isLoopEnabled: isLoopEnabled ?? this.isLoopEnabled,
      playSpeed: playSpeed ?? this.playSpeed,
    );
  }
}

class ScoreNotifier extends StateNotifier<ScoreState> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  ScoreNotifier() : super(ScoreState()) {
    _initStreams();
  }

  void _initStreams() {
    _posSub = _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _durSub = _player.durationStream.listen((dur) {
      state = state.copyWith(duration: dur ?? Duration.zero);
    });
    _stateSub = _player.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.playing,
        isLoading: playerState.processingState == ProcessingState.buffering ||
                  playerState.processingState == ProcessingState.loading,
      );
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> loadSong(String instrument, PracticeSong song) async {
    state = state.copyWith(isLoading: true, position: Duration.zero, duration: Duration.zero);
    
    // Si estamos en Melodía, forzamos audio de melodía
    if (!state.isArrangementMode) {
      state = state.copyWith(isAudioArrangement: false);
    }

    final url = _getAudioUrl(instrument, song);
    try {
      await _player.setUrl(url);
      await _player.setSpeed(state.playSpeed);
      await _player.setLoopMode(state.isLoopEnabled ? LoopMode.one : LoopMode.off);
    } catch (e) {
      print("Error loading audio: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  String _getAudioUrl(String instrument, PracticeSong song) {
    final baseName = song.melodyFileName.replaceAll('.png', '');
    if (state.isAudioArrangement && song.hasArrangementDownloaded) {
      return 'https://partituras.iglesiacristianabelen.com/audios/$instrument/${baseName}_$instrument.mp3';
    } else {
      return 'https://partituras.iglesiacristianabelen.com/audios/base/$baseName.mp3';
    }
  }

  void playPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  void setSpeed(double speed) {
    state = state.copyWith(playSpeed: speed);
    _player.setSpeed(speed);
  }

  void toggleLoop() {
    final next = !state.isLoopEnabled;
    state = state.copyWith(isLoopEnabled: next);
    _player.setLoopMode(next ? LoopMode.one : LoopMode.off);
  }

  void toggleScoreMode() {
    final nextMode = !state.isArrangementMode;
    state = state.copyWith(
      isArrangementMode: nextMode,
      // Si pasamos a melodía, el audio DEBE ser melodía obligatoriamente
      isAudioArrangement: nextMode ? state.isAudioArrangement : false,
    );
  }

  Future<void> toggleAudioMode(String instrument, PracticeSong song) async {
    if (!state.isArrangementMode) return; // Regla: solo en modo arreglo se cambia audio

    final nextAudioArr = !state.isAudioArrangement;
    final currentPos = _player.position;
    final wasPlaying = _player.playing;

    state = state.copyWith(isAudioArrangement: nextAudioArr, isLoading: true);
    
    final url = _getAudioUrl(instrument, song);
    try {
      await _player.setUrl(url);
      // Lógica de Sincronización (Hot Swap)
      await _player.seek(currentPos);
      if (wasPlaying) _player.play();
    } catch (e) {
      print("Error switching audio: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void reset() {
    _player.stop();
    state = state.copyWith(
      position: Duration.zero,
      duration: Duration.zero,
      isPlaying: false,
    );
  }

  void toggleUiVisibility() {
    state = state.copyWith(isUiVisible: !state.isUiVisible);
  }

  void setUiVisibility(bool visible) {
    state = state.copyWith(isUiVisible: visible);
  }
}

final scoreProvider = StateNotifierProvider<ScoreNotifier, ScoreState>((ref) => ScoreNotifier());