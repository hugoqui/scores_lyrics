import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScoreState {
  final bool isArrangementMode;
  final bool isUiVisible;
  final Duration position;
  final Duration duration;

  ScoreState({
    this.isArrangementMode = true,
    this.isUiVisible = true,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  ScoreState copyWith({
    bool? isArrangementMode,
    bool? isUiVisible,
    Duration? position,
    Duration? duration,
  }) {
    return ScoreState(
      isArrangementMode: isArrangementMode ?? this.isArrangementMode,
      isUiVisible: isUiVisible ?? this.isUiVisible,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class ScoreNotifier extends StateNotifier<ScoreState> {
  ScoreNotifier() : super(ScoreState());

  void toggleScoreMode() {
    state = state.copyWith(isArrangementMode: !state.isArrangementMode);
  }

  void toggleUiVisibility() {
    state = state.copyWith(isUiVisible: !state.isUiVisible);
  }

  void setUiVisibility(bool visible) {
    state = state.copyWith(isUiVisible: visible);
  }
}

final scoreProvider = StateNotifierProvider<ScoreNotifier, ScoreState>((ref) => ScoreNotifier());