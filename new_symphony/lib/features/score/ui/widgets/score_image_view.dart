import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/features/score/providers/annotation_provider.dart';
import 'package:new_symphony/features/score/ui/widgets/drawing_canvas.dart';
import 'package:new_symphony/features/score/ui/widgets/annotation_toolbar.dart';

class ScoreImageView extends ConsumerStatefulWidget {
  final String instrument;
  final String fileName;
  final VoidCallback onTap;  

  const ScoreImageView({
    super.key,
    required this.instrument,
    required this.fileName,
    required this.onTap,    
  });

  @override
  ConsumerState<ScoreImageView> createState() => _ScoreImageViewState();
}

class _ScoreImageViewState extends ConsumerState<ScoreImageView> {
  Size? _imageSize;
  late String _noteKey;

  late PhotoViewController _photoViewController;
  late Future<File> _fileFuture;

  @override
  void initState() {
    super.initState();
    _noteKey = '${widget.instrument}_${widget.fileName}';
    _photoViewController = PhotoViewController();
    _fileFuture = _getScoreFile();
    _calculateImageSize();
  }

  @override
  void didUpdateWidget(ScoreImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName || oldWidget.instrument != widget.instrument) {
      setState(() {
        _noteKey = '${widget.instrument}_${widget.fileName}';
        _photoViewController.reset(); // Resetear el controlador al cambiar de archivo
        _fileFuture = _getScoreFile();
      });
      _calculateImageSize();
    }
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  Future<void> _calculateImageSize() async {
    final file = await _fileFuture;
    if (!file.existsSync()) return;

    final Completer<Size> completer = Completer();
    final Image image = Image.file(file);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (!completer.isCompleted) {
          completer.complete(Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          ));
        }
      }),
    );

    final size = await completer.future;
    if (mounted) setState(() => _imageSize = size);
  }
  Future<File> _getScoreFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/${widget.instrument}/${widget.fileName}');
  }

  @override
  Widget build(BuildContext context) {
    final annotationState = ref.watch(annotationProvider(_noteKey));
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return FutureBuilder<File>(
      future: _fileFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || _imageSize == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final file = snapshot.data!;
        if (!file.existsSync()) {
          return const Center(child: Text('Archivo no encontrado', style: TextStyle(color: AppColors.error)));
        }

        // El PhotoView ahora solo muestra la imagen, sin el DrawingCanvas dentro
        return PopScope(
          // Bloquear el gesto de "atrás" nativo si estamos dibujando
          canPop: !annotationState.isDrawingMode,
          child: SizedBox.expand(
            child: Stack(
              children: [
                PhotoView.customChild(
                  key: ValueKey(_noteKey), // Forza un reset completo del widget al cambiar la imagen
                  controller: _photoViewController, // Pasamos el controlador
                  backgroundDecoration: const BoxDecoration(color: AppColors.white),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  disableGestures: annotationState.isDrawingMode, // Deshabilitar gestos de PhotoView al dibujar
                  onTapUp: (context, details, controllerValue) {
                    if (!annotationState.isDrawingMode) {
                      widget.onTap(); // Toggle UI visibility only if not in drawing mode
                    }
                  },
                  childSize: _imageSize,
                  child: Image.file(
                    file,
                    width: _imageSize!.width,
                    height: _imageSize!.height,
                    fit: BoxFit.contain,
                  ),
                ),
                // El DrawingCanvas ahora es un overlay de pantalla completa
                if (annotationState.isVisible && _imageSize != null)
                  IgnorePointer(
                    ignoring: !annotationState.isDrawingMode, // Ignore pointer events if NOT in drawing mode
                    child: DrawingCanvas(
                      noteKey: _noteKey,
                      imageSize: _imageSize!,
                      photoViewController: _photoViewController,
                    ),
                  ),

                // La barra de herramientas (Lápiz)
                Positioned(
                  top: annotationState.isDrawingMode ? 20 : (isLandscape ? 20 : 100),
                  left: isLandscape ? 10 : null,
                  right: isLandscape ? null : 10,
                  child: AnnotationToolbar(noteKey: _noteKey),
                ),                
              ],
            ),
          ),
        );
      },
    );
  }
}