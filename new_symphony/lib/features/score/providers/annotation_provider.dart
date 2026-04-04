import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/features/score/models/annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnotationState {
  final List<DrawingStroke> strokes;
  final bool isDrawingMode;
  final bool isVisible;
  final int selectedColor;

  AnnotationState({
    this.strokes = const [],
    this.isDrawingMode = false,
    this.isVisible = true,
    this.selectedColor = 0xFFFF0000, // Rojo por defecto (ARGB)
  });

  AnnotationState copyWith({
    List<DrawingStroke>? strokes,
    bool? isDrawingMode,
    bool? isVisible,
    int? selectedColor,
  }) {
    return AnnotationState(
      strokes: strokes ?? this.strokes,
      isDrawingMode: isDrawingMode ?? this.isDrawingMode,
      isVisible: isVisible ?? this.isVisible,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }
}

class AnnotationNotifier extends StateNotifier<AnnotationState> {
  final SharedPreferences _prefs;
  final String _key;

  AnnotationNotifier(this._prefs, this._key) : super(AnnotationState()) {
    _loadNotes();
  }

  void _loadNotes() {
    final data = _prefs.getString('notes_$_key');
    if (data != null) {
      try {
        final List decoded = jsonDecode(data);
        state = state.copyWith(strokes: decoded.map((s) => DrawingStroke.fromJson(s)).toList());
      } catch (_) {}
    }
  }

  void _saveNotes() {
    final encoded = jsonEncode(state.strokes.map((s) => s.toJson()).toList());
    _prefs.setString('notes_$_key', encoded);
  }

  void addStroke(DrawingStroke stroke) {
    state = state.copyWith(strokes: [...state.strokes, stroke]);
    _saveNotes();
  }

  void clear() {
    state = state.copyWith(strokes: []);
    _saveNotes();
  }

  void toggleDrawingMode() => state = state.copyWith(isDrawingMode: !state.isDrawingMode);
  void toggleVisibility() => state = state.copyWith(isVisible: !state.isVisible);
  void setColor(int color) => state = state.copyWith(selectedColor: color);
}

final annotationProvider = StateNotifierProvider.family<AnnotationNotifier, AnnotationState, String>((ref, key) {
  final prefs = getIt<SharedPreferences>();
  return AnnotationNotifier(prefs, key);
});