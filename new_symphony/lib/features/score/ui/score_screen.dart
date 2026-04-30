import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
import 'package:new_symphony/features/score/providers/annotation_provider.dart';
import 'package:new_symphony/features/score/providers/score_provider.dart';
import 'package:new_symphony/features/score/ui/widgets/score_image_view.dart';
import 'package:new_symphony/features/score/ui/widgets/floating_player_card.dart';
import 'package:new_symphony/core/constants/app_colors.dart';

class ScoreScreen extends ConsumerStatefulWidget {
  final Instrument instrument;
  final List<PracticeSong> songs;
  final int initialIndex;

  const ScoreScreen({
    super.key,
    required this.instrument,
    required this.songs,
    required this.initialIndex,
  });

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // Inicialización con un offset grande para permitir loop infinito circular
    final int virtualInitialPage = (widget.songs.length * 100) + widget.initialIndex;
    _currentIndex = virtualInitialPage;
    _pageController = PageController(initialPage: virtualInitialPage);
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Cargar audio inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scoreProvider.notifier).loadSong(
        widget.instrument.path, 
        widget.songs[_currentIndex % widget.songs.length]
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scoreProvider);
    if (widget.songs.isEmpty) return const Scaffold(body: Center(child: Text('No hay cantos')));

    final int realIndex = _currentIndex % widget.songs.length;
    final currentSong = widget.songs[realIndex];

    // Calculamos la noteKey del canto visible actualmente para saber si se está dibujando
    String fileForNoteKey = currentSong.melodyFileName;
    if (state.isArrangementMode && currentSong.hasArrangementDownloaded) {
      fileForNoteKey = currentSong.arrangementFileName!;
    }
    final String noteKey = '${widget.instrument.path}_$fileForNoteKey';
    final bool isDrawing = ref.watch(annotationProvider(noteKey).select((s) => s.isDrawingMode));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: (state.isUiVisible && !isDrawing) // Ocultar AppBar si estamos dibujando
          ? AppBar(
              title: Text(currentSong.title),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: Stack(
        children: [
          // 1. Capa de la Partitura (Fondo)
          PageView.builder(
            controller: _pageController,
            physics: isDrawing ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            onPageChanged: (index) {
              final int newRealIndex = index % widget.songs.length;
              setState(() => _currentIndex = index);
              ref.read(scoreProvider.notifier).loadSong(
                widget.instrument.path, 
                widget.songs[newRealIndex]
              );
            },
            itemBuilder: (context, index) {
              final int itemRealIndex = index % widget.songs.length;
              final song = widget.songs[itemRealIndex];
              String fileToShow = song.melodyFileName;
              if (state.isArrangementMode && song.hasArrangementDownloaded) {
                fileToShow = song.arrangementFileName!;
              }

              return ScoreImageView(
                instrument: widget.instrument.path,
                fileName: fileToShow,
                onTap: () => ref.read(scoreProvider.notifier).toggleUiVisibility(),
              );
            },
          ),

          // 2. Capa del Reproductor (Encima)
          if (state.isUiVisible)
            SafeArea(
              left: false,
              bottom: false,
              child: Align(
                alignment: MediaQuery.of(context).orientation == Orientation.landscape
                    ? Alignment.centerRight
                    : Alignment.bottomCenter,
                child: FloatingPlayerCard(
                  hasArrangement: currentSong.hasArrangementDownloaded,
                  isArrangementScore: state.isArrangementMode && currentSong.hasArrangementDownloaded,
                  isArrangementAudio: state.isAudioArrangement,
                  isLoopEnabled: state.isLoopEnabled,
                  playSpeed: state.playSpeed,
                  position: state.position,
                  duration: state.duration,
                  onToggleAudioMode: () => ref.read(scoreProvider.notifier).toggleAudioMode(
                        widget.instrument.path,
                        currentSong,
                      ),
                  onToggleScoreMode: () => ref.read(scoreProvider.notifier).toggleScoreMode(),
                  onToggleLoop: () => ref.read(scoreProvider.notifier).toggleLoop(),
                  onChangeSpeed: (s) => ref.read(scoreProvider.notifier).setSpeed(s),
                  onSeek: (d) => ref.read(scoreProvider.notifier).seek(d),
                  onPlayPause: () => ref.read(scoreProvider.notifier).playPause(),
                  isPlaying: state.isPlaying,
                ),
              ),
            ),
        ],
      ),
    );
  }
}