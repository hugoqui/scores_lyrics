import 'dart:math';
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
          if (annotationState.activeTool == AnnotationTool.pencil) {
            _currentPoints.add(OffsetPoint(details.localPosition.dx, details.localPosition.dy));
          } else {
            // Para formas, solo guardamos el punto inicial y el actual como final
            if (_currentPoints.length > 1) {
              _currentPoints[1] = OffsetPoint(details.localPosition.dx, details.localPosition.dy);
            } else {
              _currentPoints.add(OffsetPoint(details.localPosition.dx, details.localPosition.dy));
            }
          }
        });
      } : null,
      onPanEnd: annotationState.isDrawingMode ? (_) {
        if (_currentPoints.isNotEmpty) {
          notifier.addStroke(DrawingStroke(
            points: List.from(_currentPoints),
            color: annotationState.selectedColor,
            tool: annotationState.activeTool, // Asegúrate de añadir este campo al modelo
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
          tempStrokes: annotationState.tempStrokes,
          currentPoints: _currentPoints,
          currentColor: annotationState.selectedColor,
          activeTool: annotationState.activeTool,
          isVisible: annotationState.isVisible,
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<DrawingStroke> tempStrokes;
  final List<OffsetPoint> currentPoints;
  final int currentColor;
  final AnnotationTool activeTool;
  final bool isVisible;

  _CanvasPainter({
    required this.strokes,
    required this.tempStrokes,
    required this.currentPoints,
    required this.currentColor,
    required this.activeTool,
    required this.isVisible,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    if (isVisible) {
      // Dibujamos las permanentes
      for (final stroke in strokes) {
        _drawStroke(canvas, stroke, paint);
      }
      // Dibujamos las temporales (borrador)
      for (final stroke in tempStrokes) {
        _drawStroke(canvas, stroke, paint);
      }
    }

    // Dibujamos el trazo/forma actual en progreso
    paint.color = Color(currentColor);
    if (currentPoints.isNotEmpty) {
      _drawShape(canvas, currentPoints, activeTool, paint);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke, Paint paint) {
    paint.color = Color(stroke.color);
    final tool = stroke.tool; // Asumiendo que el modelo ahora tiene 'tool'
    _drawShape(canvas, stroke.points, tool, paint);
  }

  void _drawShape(Canvas canvas, List<OffsetPoint> points, AnnotationTool tool, Paint paint) {
    if (points.isEmpty) return;
    
    if (tool == AnnotationTool.pencil) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i].toOffset(), points[i+1].toOffset(), paint);
      }
    } else if (points.length >= 2) {
      final start = points.first.toOffset();
      final end = points.last.toOffset();
      final rect = Rect.fromPoints(start, end);

      switch (tool) {
        case AnnotationTool.arrow:
          canvas.drawLine(start, end, paint);
          final angle = atan2(end.dy - start.dy, end.dx - start.dx);
          const arrowSize = 15.0;
          canvas.drawLine(end, Offset(end.dx - arrowSize * cos(angle - pi/6), end.dy - arrowSize * sin(angle - pi/6)), paint);
          canvas.drawLine(end, Offset(end.dx - arrowSize * cos(angle + pi/6), end.dy - arrowSize * sin(angle + pi/6)), paint);
          break;
        case AnnotationTool.circle:
          canvas.drawOval(rect, paint..style = PaintingStyle.stroke);
          break;
        case AnnotationTool.square:
          canvas.drawRect(rect, paint..style = PaintingStyle.stroke);
          break;
        default:
          break;
      }
      paint.style = PaintingStyle.fill; // Reset para el siguiente trazo
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}