import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/features/score/models/annotation.dart';
import 'package:new_symphony/features/score/providers/annotation_provider.dart';
import 'package:photo_view/photo_view.dart';

class DrawingCanvas extends ConsumerStatefulWidget {
  final String noteKey;
  final Size imageSize; // Tamaño original de la imagen
  final PhotoViewController photoViewController; // Controlador de PhotoView

  const DrawingCanvas({super.key, required this.noteKey, required this.imageSize, required this.photoViewController});

  @override
  ConsumerState<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends ConsumerState<DrawingCanvas> {
  List<OffsetPoint> _currentPoints = [];
  StreamSubscription? _photoViewSubscription;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en la transformación de PhotoView para redibujar
    _photoViewSubscription = widget.photoViewController.outputStateStream.listen((_) {
      _onPhotoViewChange();
    });
  }

  @override
  void dispose() {
    _photoViewSubscription?.cancel();
    super.dispose();
  }
  void _onPhotoViewChange() {
    // Forzar un redibujado si la escala o posición de PhotoView cambia
    // Esto es crucial para que las anotaciones se muevan y escalen con la imagen
    if (mounted) setState(() {});
  }

  // Transforma un Offset de la pantalla a un Offset relativo a la imagen original
  Offset _transformScreenToImageCoordinates(Offset screenOffset) {
    final controller = widget.photoViewController;
    final scale = controller.scale ?? 1.0;
    final position = controller.position;

    // Calcula el tamaño de la imagen renderizada en pantalla
    final renderedImageWidth = widget.imageSize.width * scale;
    final renderedImageHeight = widget.imageSize.height * scale;

    // Calcula el offset de la imagen dentro del PhotoView (centrado)
    final imageOffset = Offset(
      (context.size!.width - renderedImageWidth) / 2 + position.dx,
      (context.size!.height - renderedImageHeight) / 2 + position.dy,
    );

    // Transforma el punto de la pantalla a la coordenada de la imagen
    return (screenOffset - imageOffset) / scale;
  }

  @override
  Widget build(BuildContext context) {
    final annotationState = ref.watch(annotationProvider(widget.noteKey));
    final notifier = ref.read(annotationProvider(widget.noteKey).notifier);

    return GestureDetector(
      // El DrawingCanvas ocupa toda la pantalla, pero su comportamiento de detección de gestos
      // depende de si estamos en modo dibujo.
      behavior: annotationState.isDrawingMode ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      onPanStart: annotationState.isDrawingMode ? (details) {
        setState(() {
          _currentPoints = [OffsetPoint.fromOffset(_transformScreenToImageCoordinates(details.localPosition))];
        });
      } : null,
      onPanUpdate: annotationState.isDrawingMode ? (details) {
        setState(() {
          if (annotationState.activeTool == AnnotationTool.pencil ||
              annotationState.activeTool == AnnotationTool.eraser) {
            _currentPoints.add(OffsetPoint.fromOffset(_transformScreenToImageCoordinates(details.localPosition)));
          } else {
            // Para formas, solo guardamos el punto inicial y el actual como final
            if (_currentPoints.length > 1) {
              _currentPoints[1] = OffsetPoint.fromOffset(_transformScreenToImageCoordinates(details.localPosition));
            } else {
              _currentPoints.add(OffsetPoint.fromOffset(_transformScreenToImageCoordinates(details.localPosition)));
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
      // onTap: annotationState.isDrawingMode ? () {} : widget.onTap, // REMOVED: onTap is now handled by PhotoView
      child: CustomPaint(
        size: Size.infinite, // Ocupa todo el espacio disponible
        painter: _CanvasPainter(
          strokes: annotationState.strokes,
          tempStrokes: annotationState.tempStrokes,
          currentPoints: _currentPoints,
          currentColor: annotationState.selectedColor,
          activeTool: annotationState.activeTool,
          isVisible: annotationState.isVisible,
          imageSize: widget.imageSize,
          photoViewController: widget.photoViewController,
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
  final Size imageSize; // Tamaño original de la imagen
  final PhotoViewController photoViewController; // Controlador de PhotoView

  _CanvasPainter({
    required this.strokes,
    required this.tempStrokes,
    required this.currentPoints,
    required this.currentColor,
    required this.activeTool,
    required this.isVisible,
    required this.imageSize,
    required this.photoViewController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    
    // Obtenemos la escala y posición actual de PhotoView
    final scale = photoViewController.scale ?? 1.0;
    final position = photoViewController.position;

    // Calculamos el tamaño de la imagen renderizada en pantalla
    final renderedImageWidth = imageSize.width * scale;
    final renderedImageHeight = imageSize.height * scale;

    // Calculamos el offset de la imagen dentro del PhotoView (centrado)
    final imageOffset = Offset(
      (size.width - renderedImageWidth) / 2 + position.dx,
      (size.height - renderedImageHeight) / 2 + position.dy,
    );

    // Usamos saveLayer para que BlendMode.clear afecte solo a esta capa de dibujo
    // y no borre la imagen de la partitura que está debajo en el Stack.
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    // Creamos una capa para dibujar las anotaciones transformadas
    canvas.save();
    canvas.translate(imageOffset.dx, imageOffset.dy);
    canvas.scale(scale);

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
    canvas.restore(); // Restauramos la capa
    canvas.restore(); // Restauramos la capa de saveLayer
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke, Paint paint) {
    paint.color = Color(stroke.color);
    final tool = stroke.tool; // Asumiendo que el modelo ahora tiene 'tool'
    _drawShape(canvas, stroke.points, tool, paint);
  }

  void _drawShape(Canvas canvas, List<OffsetPoint> points, AnnotationTool tool, Paint paint) {
    if (points.isEmpty) return;
    
    // Configuramos el comportamiento según la herramienta
    if (tool == AnnotationTool.eraser) {
      paint.blendMode = BlendMode.clear;
      paint.strokeWidth = 20.0; // Borrador más grueso para facilitar el uso
    } else {
      paint.blendMode = BlendMode.srcOver;
      paint.strokeWidth = 3.0;
    }

    if (tool == AnnotationTool.pencil || tool == AnnotationTool.eraser) {
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