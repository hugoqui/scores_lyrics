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

  // Método para mostrar la confirmación
  Future<void> _confirmDownloadAll(DownloadState state) async {
    final songs = state.songs.asData?.value ?? [];
    if (songs.isEmpty) return;

    final count = songs.length;
    // Cálculo aproximado: asumiendo un promedio de 250kb por imagen/archivo
    final totalSizeMb = (count * 0.25).toStringAsFixed(1);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descargar todo'),
        content: Text(
          'Se descargarán $count archivos (aprox. $totalSizeMb MB).\n\n'
          'Si ya tienes archivos descargados, se sobreescribirán con la versión más reciente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DESCARGAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(downloadProvider(widget.instrument.path).notifier).downloadAll();
    }
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
            // Ahora siempre está habilitado a menos que ya esté descargando
            onPressed: downloadState.isDownloadingAll 
                ? null 
                : () => _confirmDownloadAll(downloadState),
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
                    title: Text(
                      song.fileName
                          .replaceAll('.png', '')
                          .replaceAll('_', ' ')
                          .split(' ')
                          .where((word) => word.isNotEmpty)
                          .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
                          .join(' '),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        song.isDownloaded ? Icons.refresh : Icons.download, 
                        color: Theme.of(context).colorScheme.onSurface
                      ),
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
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).colorScheme.onSurface,),        
      );
    }
    if (song.isDownloaded) {
      return const Icon(Icons.check, color: AppColors.accent);
    }
    return const SizedBox.shrink();
  }
}