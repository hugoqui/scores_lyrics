import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/features/score/models/annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AnnotationTool { pencil, arrow, circle, square, eraser }

class AnnotationState {
  final List<DrawingStroke> strokes;
  final List<DrawingStroke> tempStrokes;
  final bool isDrawingMode;
  final bool isVisible;
  final int selectedColor;
  final AnnotationTool activeTool;

  AnnotationState({
    this.strokes = const [],
    this.tempStrokes = const [],
    this.isDrawingMode = false,
    this.isVisible = true,
    this.selectedColor = 0xFFFF0000, // Rojo por defecto (ARGB)
    this.activeTool = AnnotationTool.pencil,
  });

  AnnotationState copyWith({
    List<DrawingStroke>? strokes,
    List<DrawingStroke>? tempStrokes,
    bool? isDrawingMode,
    bool? isVisible,
    int? selectedColor,
    AnnotationTool? activeTool,
  }) {
    return AnnotationState(
      strokes: strokes ?? this.strokes,
      tempStrokes: tempStrokes ?? this.tempStrokes,
      isDrawingMode: isDrawingMode ?? this.isDrawingMode,
      isVisible: isVisible ?? this.isVisible,
      selectedColor: selectedColor ?? this.selectedColor,
      activeTool: activeTool ?? this.activeTool,
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
    if (data != null && data != 'null') {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          final loadedStrokes = decoded
              .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
              .toList();
          state = state.copyWith(strokes: loadedStrokes);
        }
      } catch (e) {
        print('Error loading notes for $_key: $e');
      }
    }
  }

  void _saveNotes() {
    final encoded = jsonEncode(state.strokes.map((s) => s.toJson()).toList());
    _prefs.setString('notes_$_key', encoded);
  }

  void addStroke(DrawingStroke stroke) {
    // Durante el modo dibujo, guardamos en la lista temporal
    state = state.copyWith(tempStrokes: [...state.tempStrokes, stroke]);
  }

  void confirmChanges() {
    // Al confirmar, pasamos lo temporal a lo permanente y guardamos
    state = state.copyWith(
      strokes: [...state.strokes, ...state.tempStrokes],
      tempStrokes: [],
      isDrawingMode: false,
    );
    _saveNotes();
  }

  void cancelChanges() {
    // Al cancelar, simplemente vaciamos lo temporal y salimos del modo
    state = state.copyWith(tempStrokes: [], isDrawingMode: false);
  }

  void clear() {
    state = state.copyWith(strokes: [], tempStrokes: []);
    _saveNotes();
  }

  void setTool(AnnotationTool tool) => state = state.copyWith(activeTool: tool);
  void toggleDrawingMode() => state = state.copyWith(isDrawingMode: !state.isDrawingMode);
  void toggleVisibility() => state = state.copyWith(isVisible: !state.isVisible);
  void setColor(int color) => state = state.copyWith(selectedColor: color);
}

final annotationProvider = StateNotifierProvider.family<AnnotationNotifier, AnnotationState, String>((ref, key) {
  final prefs = getIt<SharedPreferences>();
  return AnnotationNotifier(prefs, key);
});