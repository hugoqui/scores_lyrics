import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:new_symphony/core/constants/app_colors.dart';

class ScoreImageView extends StatelessWidget {
  final String instrument;
  final String fileName;
  final VoidCallback onTap;

  const ScoreImageView({
    super.key,
    required this.instrument,
    required this.fileName,
    required this.onTap,
  });

  Future<File> _getScoreFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$instrument/$fileName');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _getScoreFile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final file = snapshot.data!;
        if (!file.existsSync()) {
          return const Center(child: Text('Archivo no encontrado', style: TextStyle(color: AppColors.error)));
        }

        return GestureDetector(
          onTap: onTap,
          child: PhotoView(
            imageProvider: FileImage(file),
            backgroundDecoration: const BoxDecoration(color: AppColors.white),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        );
      },
    );
  }
}