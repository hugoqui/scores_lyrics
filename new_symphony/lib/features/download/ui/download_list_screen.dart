import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/download/providers/download_provider.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';

class DownloadListScreen extends ConsumerStatefulWidget {
  final Instrument instrument;
  const DownloadListScreen({super.key, required this.instrument});

  @override
  ConsumerState<DownloadListScreen> createState() => _DownloadListScreenState();
}

class _DownloadListScreenState extends ConsumerState<DownloadListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadProvider(widget.instrument.path));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.instrument.name),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download_for_offline, color: AppColors.white),
            label: const Text('Descargar todo', style: TextStyle(color: AppColors.white)),
            onPressed: downloadState.isDownloadingAll 
                ? null 
                : () => ref.read(downloadProvider(widget.instrument.path).notifier).downloadAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar canto...',
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(downloadProvider(widget.instrument.path).notifier).filterSongs('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => ref.read(downloadProvider(widget.instrument.path).notifier).filterSongs(value),
            ),
          ),
          if (downloadState.isDownloadingAll)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: downloadState.downloadProgress,
                    backgroundColor: AppColors.lightGrey,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    'Descargando: ${(downloadState.downloadProgress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                ],
              ),
            ),
          Expanded(
            child: downloadState.songs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (songs) => ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return ListTile(
                    leading: _buildLeading(song),
                    title: Text(song.fileName.replaceAll('.png', '').replaceAll('_', ' ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.download, color: AppColors.primary),
                      onPressed: () => ref.read(downloadProvider(widget.instrument.path).notifier).download(song.fileName),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeading(DownloadableSong song) {
    if (song.isDownloading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }
    if (song.isDownloaded) {
      return const Icon(Icons.check, color: AppColors.accent);
    }
    return const Icon(Icons.check_box_outline_blank, color: AppColors.grey);
  }
}