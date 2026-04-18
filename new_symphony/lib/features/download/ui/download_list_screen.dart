import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/download/providers/download_provider.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';

class DownloadListScreen extends ConsumerStatefulWidget {
  final Instrument instrument;
  const DownloadListScreen({super.key, required this.instrument});

  @override
  ConsumerState<DownloadListScreen> createState() => _DownloadListScreenState();
}

class _DownloadListScreenState extends ConsumerState<DownloadListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Actualizar los acordes desde el endpoint apenas entramos a la vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<ScoreRepository>().fetchApiSongs().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Método para mostrar la confirmación
  Future<void> _confirmDownloadAll(DownloadState state) async {
    final songs = state.songs.asData?.value ?? [];
    
    // Deduplicamos por nombre de archivo para el conteo correcto
    final uniqueFileNames = songs.map((s) => s.fileName).toSet();
    if (uniqueFileNames.isEmpty) return;

    final count = uniqueFileNames.length;
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
          InkWell(
            onTap: downloadState.isDownloadingAll 
                ? null 
                : () => _confirmDownloadAll(downloadState),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_for_offline, 
                    color: downloadState.isDownloadingAll ? AppColors.white.withOpacity(0.5) : AppColors.white,
                    size: 20,
                  ),
                  Text(
                    'Descargar Todo',
                    style: TextStyle(
                      fontSize: 9, 
                      color: downloadState.isDownloadingAll ? AppColors.white.withOpacity(0.5) : AppColors.white
                    ),
                  ),
                ],
              ),
            ),
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
                          _debounce?.cancel();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  setState(() => _searchQuery = value);
                });
              },
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
              data: (songs) {
                final scoreRepo = getIt<ScoreRepository>();

                // 1. Deduplicamos por Título Real de la API
                final Map<String, DownloadableSong> uniqueSongsMap = {};
                for (var s in songs) {
                  // Intentamos encontrar el título de la API para usarlo como KEY única
                  // Esto colapsa "Abre mis ojos" y "Abre mis ojos Señor" en una sola entrada si ambos apuntan al mismo canto
                  final chord = scoreRepo.getChordForSongSync(s.fileName, widget.instrument.path);
                  final normalizedKey = scoreRepo.normalizeTitle(s.fileName);
                  
                  uniqueSongsMap[normalizedKey] = s;
                }
                final deduplicatedSongs = uniqueSongsMap.values.toList();

                // 2. Filtramos localmente la lista deduplicada
                final filteredSongs = deduplicatedSongs.where((song) {
                  final cleanTitle = song.fileName.replaceAll('.png', '').replaceAll('_', ' ');
                  return scoreRepo.normalizeTitle(cleanTitle).contains(scoreRepo.normalizeTitle(_searchQuery));
                }).toList();

                return ListView.builder(
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];
                    
                    // El endpoint manda: Obtenemos acorde real y estado de descarga real desde el repo
                    final currentChord = scoreRepo.getChordForSongSync(song.fileName, widget.instrument.path);
                    final isDownloaded = scoreRepo.isFileDownloaded(song.fileName, widget.instrument.path);

                    return ListTile(
                      leading: _buildLeading(song, isDownloaded),
                      title: Text(
                        song.fileName
                            .replaceAll('.png', '')
                            .replaceAll('_', ' ')
                            .split(' ')
                            .where((word) => word.isNotEmpty)
                            .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
                            .join(' '),
                      ),
                      subtitle: Text(
                        'Acorde: $currentChord',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isDownloaded ? Icons.refresh : Icons.download, 
                          color: Theme.of(context).colorScheme.onSurface
                        ),
                        onPressed: () => ref.read(downloadProvider(widget.instrument.path).notifier).download(song.fileName),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeading(DownloadableSong song, bool isDownloaded) {
    if (song.isDownloading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).colorScheme.onSurface,),        
      );
    }
    if (isDownloaded) {
      return const Icon(Icons.check, color: AppColors.accent);
    }
    return const SizedBox.shrink();
  }
}