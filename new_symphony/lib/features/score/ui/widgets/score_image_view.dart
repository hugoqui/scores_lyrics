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

  @override
  void initState() {
    super.initState();
    _noteKey = '${widget.instrument}_${widget.fileName}';
    _calculateImageSize();
  }

  @override
  void didUpdateWidget(ScoreImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName || oldWidget.instrument != widget.instrument) {
      _noteKey = '${widget.instrument}_${widget.fileName}';
      _calculateImageSize();
    }
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
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

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

        return SizedBox.expand(
          child: Stack(
            children: [
              GestureDetector(
                onTap: widget.onTap,
                child: PhotoView.customChild(
                  backgroundDecoration: const BoxDecoration(color: AppColors.white),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  childSize: _imageSize,
                  child: Stack(
                    children: [
                      Image.file(
                        file,
                        width: _imageSize!.width,
                        height: _imageSize!.height,
                        fit: BoxFit.contain,
                      ),
                      if (annotationState.isVisible)
                        DrawingCanvas(
                          noteKey: _noteKey,
                          size: _imageSize!,
                        ),
                    ],
                  ),
                ),
              ),
              
              // La barra de herramientas (Lápiz)
              // Ajustamos la posición para que esté centrada verticalmente en landscape
              Align(
                alignment: isLandscape ? Alignment.centerLeft : Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isLandscape ? 0 : 100, // En vertical bajarla un poco de la AppBar
                    left: isLandscape ? 4 : 0,  // Pegada a la izquierda en landscape
                    right: isLandscape ? 0 : 10, // Un poco de margen en vertical
                  ),
                  child: AnnotationToolbar(noteKey: _noteKey),
                ),
              ),

              // El reproductor (Audio)
              if (widget.player != null)
                Align(
                  alignment: isLandscape ? Alignment.centerRight : Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: isLandscape ? 4 : 0, // Pegado a la derecha en landscape
                      bottom: isLandscape ? 0 : 10, // Margen abajo en vertical
                    ),
                    child: widget.player!,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}