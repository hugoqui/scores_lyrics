import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';
import 'package:new_symphony/features/live/providers/live_provider.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
import 'package:new_symphony/features/score/providers/annotation_provider.dart';
import 'package:new_symphony/features/practice/ui/widgets/song_picker_sheet.dart';
import 'package:new_symphony/features/score/ui/widgets/score_image_view.dart';

class LiveScreen extends ConsumerStatefulWidget {
  final Instrument instrument;

  const LiveScreen({super.key, required this.instrument});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  late PageController _pageController;
  bool _isFullScreen = false;
  bool _isArrangementMode = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 5000); // Página base para el loop infinito
  }

  @override
  void deactivate() {
    // Usamos Future.microtask para evitar el error de "modificar durante el build".
    // Capturamos el notifier antes de que el widget se desmonte completamente.
    final notifier = ref.read(liveProvider.notifier);
    Future.microtask(() {
      notifier.disconnect();
    });
    super.deactivate();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveProvider);
    final songsAsync = ref.watch(practiceSongsProvider(widget.instrument.path));

    // Determinamos si el swipe debe estar bloqueado por el modo dibujo
    bool isDrawing = false;
    if (liveState.liveSongList.isNotEmpty && liveState.currentIndex < liveState.liveSongList.length) {
      final currentTitle = liveState.liveSongList[liveState.currentIndex];
      final songs = songsAsync.value ?? [];
      final scoreRepo = getIt<ScoreRepository>();
      final currentSong = songs.where((s) => 
        scoreRepo.normalizeTitle(s.title) == scoreRepo.normalizeTitle(currentTitle)
      ).firstOrNull;
      
      if (currentSong != null) {
        final displayFileName = (_isArrangementMode && currentSong.arrangementFileName != null)
            ? currentSong.arrangementFileName!
            : currentSong.melodyFileName;
            
        final noteKey = '${widget.instrument.path}_$displayFileName';
        isDrawing = ref.watch(annotationProvider(noteKey).select((s) => s.isDrawingMode));
      }
    }

    // Escuchar cambios de TÍTULO para mover el visor (más confiable que el índice)
    ref.listen(liveProvider.select((s) => s.currentSongTitle), (prev, nextTitle) {
      if (_pageController.hasClients && nextTitle != null) {
        final scoreRepo = getIt<ScoreRepository>();
        final list = ref.read(liveProvider).liveSongList;
        final nextIndex = list.indexWhere((t) => scoreRepo.normalizeTitle(t) == scoreRepo.normalizeTitle(nextTitle));
        
        final listLength = list.length;
        if (listLength <= 1) return;
        if (nextIndex < 0) return;

        final currentPage = _pageController.page?.round() ?? 0;
        final currentRealIndex = currentPage % listLength;
        if (currentRealIndex == nextIndex) return;

        int diff = nextIndex - currentRealIndex;
        if (diff.abs() > listLength / 2) {
          diff = diff > 0 ? diff - listLength : diff + listLength;
        }

        _pageController.animateToPage(
          currentPage + diff,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    final bool canHaveArrangement = widget.instrument.path != 'piano' && widget.instrument.path != 'trompeta';

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _isFullScreen 
        ? null 
        : AppBar(
            title: Text(widget.instrument.name),
            actions: [
              if (canHaveArrangement)
                InkWell(
                  onTap: () => setState(() => _isArrangementMode = !_isArrangementMode),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isArrangementMode ? Icons.description : Icons.description_outlined,
                          color: _isArrangementMode ? AppColors.accent : null,
                          size: 20,
                        ),
                        Text(
                          _isArrangementMode ? 'Arreglo' : 'Melodía',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: _isArrangementMode ? FontWeight.bold : FontWeight.normal,
                            color: _isArrangementMode ? AppColors.accent : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              InkWell(
                onTap: () => _showSongListSheet(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.format_list_bulleted, size: 20),
                      Text('Lista', style: TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showAddSongSearch(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 20),
                      Text('Buscar', style: TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ),
              _ConnectionStatusIndicator(status: liveState.status),
            ],
          ),
      body: liveState.liveSongList.isEmpty
              ? const Center(child: Text('Esperando lista de cantos...'))
              : songsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (songs) {
                    return PageView.builder(
                      controller: _pageController,
                      physics: isDrawing ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                      // Sin itemCount para permitir scroll infinito
                      onPageChanged: (index) {
                        if (liveState.liveSongList.isNotEmpty) {
                          ref.read(liveProvider.notifier).updateIndex(index % liveState.liveSongList.length);
                        }
                      },
                      itemBuilder: (context, index) {
                        if (liveState.liveSongList.isEmpty) return const SizedBox.shrink();
                        final realIndex = index % liveState.liveSongList.length;
                        final songTitle = liveState.liveSongList[realIndex];
                        final scoreRepo = getIt<ScoreRepository>();
                        final song = songs.where((s) => 
                          scoreRepo.normalizeTitle(s.title) == scoreRepo.normalizeTitle(songTitle)
                        ).firstOrNull;

                        if (song == null) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingExtraLarge),
                              child: Text(
                                songTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.error, 
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          );
                        }

                        // Lógica de selección de archivo: Arreglo (si existe y está activo) o Melodía
                        final displayFileName = (_isArrangementMode && song.arrangementFileName != null)
                            ? song.arrangementFileName!
                            : song.melodyFileName;

                        return ScoreImageView(
                          key: ValueKey('${widget.instrument.path}_$displayFileName'),
                          instrument: widget.instrument.path,
                          fileName: displayFileName,
                          onTap: _toggleFullScreen,
                        );
                      },
                    );
                  },
                ),
    );
  }

  void _showAddSongSearch(BuildContext context, WidgetRef ref) {
    final liveState = ref.read(liveProvider);
    final songsAsync = ref.read(practiceSongsProvider(widget.instrument.path));

    songsAsync.whenData((songs) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SongPickerSheet(
          songs: songs,
          initialSelectedTitles: liveState.liveSongList,
          instrumentPath: widget.instrument.path,
          title: 'Agregar Cantos',
          onConfirm: (selectedTitles) {
            ref.read(liveProvider.notifier).updateLiveSongList(selectedTitles);
          },
        ),
      );
    });
  }

  void _showSongListSheet(BuildContext context, WidgetRef ref) {
    final liveState = ref.read(liveProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.borderRadiusLarge)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Lista de la Sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final currentLiveState = ref.watch(liveProvider);
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: currentLiveState.liveSongList.length,
                      itemBuilder: (context, index) {
                        final title = currentLiveState.liveSongList[index];
                        final isCurrent = index == currentLiveState.currentIndex;
                        final chord = getIt<ScoreRepository>().getChordForSongSync(title, widget.instrument.path);

                        return ListTile(
                          leading: ChordAvatar(chord: chord),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? AppColors.accent : null,
                            ),
                          ),
                          trailing: isCurrent 
                              ? const Icon(Icons.play_circle_fill, color: AppColors.accent)
                              : Text('${index + 1}', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                          selected: isCurrent,
                          onTap: () {
                            ref.read(liveProvider.notifier).updateIndex(index);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatusIndicator extends StatelessWidget {
  final String status;
  const _ConnectionStatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'online' 
        ? AppColors.accent 
        : (status == 'reconnecting' ? Colors.orange : AppColors.error);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Icon(Icons.circle, size: 12, color: color),
    );
  }
}