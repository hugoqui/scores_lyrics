import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
import 'package:new_symphony/features/score/providers/score_provider.dart';
import 'package:new_symphony/features/score/ui/widgets/score_image_view.dart';
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
    // Ocultar barra de estado al entrar si es necesario
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restaurar barras del sistema al salir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  bool _shouldShowToggle() {
    // Piano y Trompeta no suelen tener switch de arreglo según lógica heredada
    if (widget.instrument.path == 'piano' || widget.instrument.path == 'trumpet') return false;
    
    final song = widget.songs[_currentIndex];
    return song.hasArrangementDownloaded;
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
            },
            itemBuilder: (context, index) {
              final song = widget.songs[index];
              // Determinar qué archivo mostrar basado en el modo y disponibilidad
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
          if (state.isUiVisible && _shouldShowToggle())
            Positioned(
              top: 10,
              right: 10,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => ref.read(scoreProvider.notifier).toggleScoreMode(),
                child: Text(state.isArrangementMode ? 'Ver Melodía' : 'Ver Arreglo'),
              ),
            ),
          if (state.isUiVisible)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(
                  'Canto ${_currentIndex + 1} de ${widget.songs.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}