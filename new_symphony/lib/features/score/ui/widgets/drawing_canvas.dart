import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/features/score/models/annotation.dart';
import 'package:new_symphony/features/score/providers/annotation_provider.dart';

class DrawingCanvas extends ConsumerStatefulWidget {
  final String noteKey;
  final Size size;

  const DrawingCanvas({super.key, required this.noteKey, required this.size});

  @override
  ConsumerState<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends ConsumerState<DrawingCanvas> {
  List<OffsetPoint> _currentPoints = [];

  @override
  Widget build(BuildContext context) {
    final annotationState = ref.watch(annotationProvider(widget.noteKey));
    final notifier = ref.read(annotationProvider(widget.noteKey).notifier);

    return GestureDetector(
      // Si estamos dibujando, capturamos los gestos para que PhotoView no se mueva
      behavior: annotationState.isDrawingMode ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      onPanStart: annotationState.isDrawingMode ? (details) {
        setState(() {
          _currentPoints = [OffsetPoint(details.localPosition.dx, details.localPosition.dy)];
        });
      } : null,
      onPanUpdate: annotationState.isDrawingMode ? (details) {
        setState(() {
          _currentPoints.add(OffsetPoint(details.localPosition.dx, details.localPosition.dy));
        });
      } : null,
      onPanEnd: annotationState.isDrawingMode ? (_) {
        if (_currentPoints.isNotEmpty) {
          notifier.addStroke(DrawingStroke(
            points: List.from(_currentPoints),
            color: annotationState.selectedColor,
          ));
          setState(() => _currentPoints = []);
        }
      } : null,
      // Bloqueamos el tap para que no dispare el modo pantalla completa al dibujar
      onTap: annotationState.isDrawingMode ? () {} : null,
      child: CustomPaint(
        size: widget.size,
        painter: _CanvasPainter(
          strokes: annotationState.strokes,
          currentPoints: _currentPoints,
          currentColor: annotationState.selectedColor,
          isVisible: annotationState.isVisible,
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<OffsetPoint> currentPoints;
  final int currentColor;
  final bool isVisible;

  _CanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.isVisible,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    if (isVisible) {
      for (final stroke in strokes) {
        paint.color = Color(stroke.color);
        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i].toOffset(), stroke.points[i+1].toOffset(), paint);
        }
      }
    }

    paint.color = Color(currentColor);
    for (int i = 0; i < currentPoints.length - 1; i++) {
      canvas.drawLine(currentPoints[i].toOffset(), currentPoints[i+1].toOffset(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}