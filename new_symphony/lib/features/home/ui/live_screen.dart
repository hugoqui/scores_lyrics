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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void deactivate() {
    // Nos desconectamos aquí porque 'ref' aún es válido. 
    // En 'dispose' a veces ya es tarde debido al ciclo de vida de Riverpod.
    ref.read(liveProvider.notifier).disconnect();
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
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
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
                IconButton(
                  tooltip: _isArrangementMode ? 'Ver Melodía' : 'Ver Arreglo',
                  icon: Icon(
                    _isArrangementMode ? Icons.description : Icons.description_outlined,
                    color: _isArrangementMode ? AppColors.accent : null,
                  ),
                  onPressed: () => setState(() => _isArrangementMode = !_isArrangementMode),
                ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showAddSongSearch(context, ref),
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
                      itemCount: liveState.liveSongList.length,
                      onPageChanged: (index) => ref.read(liveProvider.notifier).updateIndex(index),
                      itemBuilder: (context, index) {
                        final songTitle = liveState.liveSongList[index];
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
    final songsAsync = ref.read(practiceSongsProvider(widget.instrument.path));

    songsAsync.whenData((songs) {
      List<String> selectedTitles = [];
      String searchQuery = "";
      String? selectedChord;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,        
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            final filteredSongs = songs.where((s) {
              final matchesSearch = s.title.toLowerCase().contains(searchQuery.toLowerCase());
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
                              for (final title in selectedTitles) {
                                ref.read(liveProvider.notifier).addSongManual(title);
                              }
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
                        onChanged: (val) => setModalState(() => searchQuery = val),
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
                          final isSelected = selectedTitles.contains(song.title);
                          final chord = getIt<ScoreRepository>().getChordForSongSync(song.title, widget.instrument.path);
                          
                          return CheckboxListTile(
                            secondary: _ChordAvatar(chord: chord),
                            title: Text(song.title),
                            value: isSelected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedTitles.add(song.title);
                                } else {
                                  selectedTitles.remove(song.title);
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
      );
    });
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