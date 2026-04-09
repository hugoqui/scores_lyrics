import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Widget? player;

  const ScoreImageView({
    super.key,
    required this.instrument,
    required this.fileName,
    required this.onTap,
    this.player,
  });

  @override
  ConsumerState<ScoreImageView> createState() => _ScoreImageViewState();
}

class _ScoreImageViewState extends ConsumerState<ScoreImageView> {
  Size? _imageSize;
  late String _noteKey;

  late PhotoViewController _photoViewController;

  @override
  void initState() {
    super.initState();
    _noteKey = '${widget.instrument}_${widget.fileName}';
    _photoViewController = PhotoViewController();
    _calculateImageSize();
  }

  @override
  void didUpdateWidget(ScoreImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName || oldWidget.instrument != widget.instrument) {
      _noteKey = '${widget.instrument}_${widget.fileName}';
      _photoViewController.reset(); // Resetear el controlador al cambiar de canción
      _calculateImageSize();
    }
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  Future<void> _calculateImageSize() async {
    final file = await _getScoreFile();
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

    // Escuchamos cambios en el modo de dibujo para activar/desactivar modo inmersivo
    ref.listen(annotationProvider(_noteKey).select((s) => s.isDrawingMode), (prev, next) {
      if (next != prev) {
        if (next) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        } else {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
      }
    });

    return FutureBuilder<File>(
      future: _getScoreFile(),
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
                  controller: _photoViewController, // Pasamos el controlador
                  backgroundDecoration: const BoxDecoration(color: AppColors.white),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  disableGestures: annotationState.isDrawingMode, // Deshabilitar gestos de PhotoView al dibujar
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
                  DrawingCanvas(
                    noteKey: _noteKey,
                    imageSize: _imageSize!,
                    photoViewController: _photoViewController,
                    onTap: widget.onTap, // Pasamos el onTap para el toggle de UI
                  ),

                // La barra de herramientas (Lápiz)
                Positioned(
                  top: annotationState.isDrawingMode ? 20 : (isLandscape ? 20 : 100),
                  left: isLandscape ? 10 : null,
                  right: isLandscape ? null : 10,
                  child: AnnotationToolbar(noteKey: _noteKey),
                ),
                // El reproductor (Audio) - Ocultación animada y bloqueo de toques
                if (widget.player != null)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: annotationState.isDrawingMode ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: annotationState.isDrawingMode,
                      child: Positioned(
                        top: isLandscape ? 100 : null,
                        bottom: isLandscape ? null : 0,
                        left: isLandscape ? null : 0,
                        right: isLandscape ? 10 : 0,
                        child: isLandscape 
                          ? widget.player!
                          : Center(child: widget.player!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}