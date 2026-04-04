import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
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
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Cargar audio inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scoreProvider.notifier).loadSong(
        widget.instrument.path, 
        widget.songs[_currentIndex]
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restaurar barras del sistema al salir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scoreProvider);
    final currentSong = widget.songs[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: state.isUiVisible
          ? AppBar(
              title: Text(currentSong.title),
              backgroundColor: AppColors.primary.withOpacity(0.8),
            )
          : null,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.songs.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              ref.read(scoreProvider.notifier).loadSong(
                widget.instrument.path, 
                widget.songs[index]
              );
            },
            itemBuilder: (context, index) {
              final song = widget.songs[index];
              // Determinar qué archivo mostrar basado en el modo y disponibilidad
              String fileToShow = song.melodyFileName;
              if (state.isArrangementMode && song.hasArrangementDownloaded) {
                fileToShow = song.arrangementFileName!;
              }

              return Align(
                alignment: Alignment.topCenter,
                child: ScoreImageView(
                  instrument: widget.instrument.path,
                  fileName: fileToShow,
                  onTap: () => ref.read(scoreProvider.notifier).toggleUiVisibility(),
                ),
              );
            },
          ),
          if (state.isUiVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [                  
                  FloatingPlayerCard(
                    isArrangementScore: state.isArrangementMode && currentSong.hasArrangementDownloaded,
                    isArrangementAudio: state.isAudioArrangement,
                    isLoopEnabled: state.isLoopEnabled,
                    playSpeed: state.playSpeed,
                    position: state.position,
                    duration: state.duration,
                    onToggleAudioMode: () => ref.read(scoreProvider.notifier).toggleAudioMode(
                      widget.instrument.path, 
                      currentSong
                    ),
                    onToggleScoreMode: () => ref.read(scoreProvider.notifier).toggleScoreMode(),
                    onToggleLoop: () => ref.read(scoreProvider.notifier).toggleLoop(),
                    onChangeSpeed: (s) => ref.read(scoreProvider.notifier).setSpeed(s),
                    onSeek: (d) => ref.read(scoreProvider.notifier).seek(d),
                    onPlayPause: () => ref.read(scoreProvider.notifier).playPause(),
                    isPlaying: state.isPlaying,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}