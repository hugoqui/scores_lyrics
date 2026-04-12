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
    _pageController = PageController();
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
      final currentSong = songs.where((s) => s.title.toLowerCase() == currentTitle.toLowerCase()).firstOrNull;
      
      if (currentSong != null) {
        final displayFileName = (_isArrangementMode && currentSong.arrangementFileName != null)
            ? currentSong.arrangementFileName!
            : currentSong.melodyFileName;
            
        final noteKey = '${widget.instrument.path}_$displayFileName';
        isDrawing = ref.watch(annotationProvider(noteKey).select((s) => s.isDrawingMode));
      }
    }

    // Escuchar cambios de índice desde el servidor para mover el PageView
    ref.listen(liveProvider.select((s) => s.currentIndex), (prev, next) {
      if (_pageController.hasClients) {
        final listLength = liveState.liveSongList.length;
        if (listLength <= 1) return;

        final currentPage = _pageController.page?.round() ?? 0;
        final currentRealIndex = currentPage % listLength;

        if (currentRealIndex == next) return;

        // Encontrar el salto más corto para el loop circular
        int diff = next - currentRealIndex;
        if (diff > listLength / 2) diff -= listLength;
        if (diff < -listLength / 2) diff += listLength;

        _pageController.animateToPage(
          currentPage + diff,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    final bool canHaveArrangement = widget.instrument.path != 'piano' && widget.instrument.path != 'trompeta';

    // Inicialización del PageController con un offset grande para permitir loop infinito
    if (_isFirstLoad && liveState.liveSongList.isNotEmpty) {
      _isFirstLoad = false;
      final length = liveState.liveSongList.length;
      final initialVirtualPage = (length * 100) + liveState.currentIndex;
      _pageController = PageController(initialPage: initialVirtualPage);
    }

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
                      key: ValueKey('live_page_view_${liveState.liveSongList.length}'), 
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
                        final song = songs.where((s) => 
                          s.title.toLowerCase() == songTitle.toLowerCase()
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
      List<String> selectedTitles = List.from(liveState.liveSongList);
      String searchQuery = "";
      String? selectedChord;
      Timer? debounce;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,        
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            String normalize(String text) => text.toLowerCase()
                .replaceAll('á', 'a')
                .replaceAll('é', 'e')
                .replaceAll('í', 'i')
                .replaceAll('ó', 'o')
                .replaceAll('ú', 'u')
                .replaceAll('ü', 'u');

            final filteredSongs = songs.where((s) {
              final matchesSearch = normalize(s.title).contains(normalize(searchQuery));
              final currentChord = getIt<ScoreRepository>().getChordForSongSync(s.title, widget.instrument.path);
              final matchesChord = selectedChord == null || currentChord == selectedChord;
              return matchesSearch && matchesChord;
            }).toList();

            final chordOptions = ["C", "Eb", "F", "G", "Bb"];

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) => Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.borderRadiusLarge)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text('Agregar Cantos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: selectedTitles.isEmpty ? null : () {
                              ref.read(liveProvider.notifier).updateLiveSongList(selectedTitles);
                              Navigator.pop(context);
                            },
                            child: Text('Agregar (${selectedTitles.length})'),                          
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar canto...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          if (debounce?.isActive ?? false) debounce?.cancel();
                          debounce = Timer(const Duration(milliseconds: 500), () {
                            setModalState(() => searchQuery = val);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text("Todos"),
                            selected: selectedChord == null,
                            onSelected: (val) => setModalState(() => selectedChord = null),
                          ),
                          ...chordOptions.map((chord) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text(chord),
                              selected: selectedChord == chord,
                              onSelected: (val) => setModalState(() => selectedChord = val ? chord : null),
                            ),
                          )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          // IMPORTANTE: Usamos normalización para comparar contra la lista de la sesión
                          // Esto permite que el check aparezca aunque el servidor mande títulos sin tildes.
                          final isSelected = selectedTitles.any((t) => normalize(t) == normalize(song.title));
                          final chord = getIt<ScoreRepository>().getChordForSongSync(song.title, widget.instrument.path);
                          
                          return CheckboxListTile(
                            secondary: _ChordAvatar(chord: chord),
                            title: Text(song.title),
                            value: isSelected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  if (!isSelected) selectedTitles.add(song.title);
                                } else {
                                  selectedTitles.removeWhere((t) => normalize(t) == normalize(song.title));
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ).then((_) => debounce?.cancel());
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
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: liveState.liveSongList.length,
                  itemBuilder: (context, index) {
                    final title = liveState.liveSongList[index];
                    final isCurrent = index == liveState.currentIndex;
                    final chord = getIt<ScoreRepository>().getChordForSongSync(title, widget.instrument.path);

                    return ListTile(
                      leading: _ChordAvatar(chord: chord),
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
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
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

class _ChordAvatar extends StatelessWidget {
  final String chord;
  const _ChordAvatar({required this.chord});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(
          chord,
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}