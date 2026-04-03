import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/download/providers/download_provider.dart';
import 'package:new_symphony/core/constants/app_colors.dart';

class DownloadListScreen extends ConsumerWidget {
  final Instrument instrument;
  const DownloadListScreen({super.key, required this.instrument});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsState = ref.watch(downloadProvider(instrument.path));

    return Scaffold(
      appBar: AppBar(
        title: Text('Partituras: ${instrument.name}'),
      ),
      body: songsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (songs) => ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              title: Text(song.fileName.replaceAll('.png', '').replaceAll('_', ' ')),
              trailing: _buildTrailing(ref, song),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrailing(WidgetRef ref, DownloadableSong song) {
    if (song.isDownloaded) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    
    if (song.isDownloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      icon: const Icon(Icons.download, color: AppColors.accent),
      onPressed: () => ref.read(downloadProvider(instrument.path).notifier).download(song.fileName),
    );
  }
}