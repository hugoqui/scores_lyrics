import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/live/providers/live_provider.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
import 'package:new_symphony/features/score/ui/widgets/score_image_view.dart';

class LiveScreen extends ConsumerStatefulWidget {
  final Instrument instrument;

  const LiveScreen({super.key, required this.instrument});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  @override
  void dispose() {
    // Nos desconectamos automáticamente del servidor al salir de la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveProvider.notifier).disconnect();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveProvider);
    final songsAsync = ref.watch(practiceSongsProvider(widget.instrument.path));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('En Vivo: ${widget.instrument.name}'),
        actions: [
          _ConnectionStatusIndicator(status: liveState.status),
        ],
      ),
      body: liveState.status != 'online' && liveState.status != 'reconnecting'
          ? const Center(child: Text('Desconectado del servidor de transmisión'))
          : liveState.currentSongTitle == null
              ? const Center(child: Text('Esperando que el administrador seleccione un canto...'))
              : songsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (songs) {
                    // Buscamos la canción por título ignorando mayúsculas/minúsculas
                    final song = songs.where((s) => 
                      s.title.toLowerCase() == liveState.currentSongTitle!.toLowerCase()
                    ).firstOrNull;

                    if (song == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                          child: Text(
                            'El canto "${liveState.currentSongTitle}" no se encuentra descargado para ${widget.instrument.name}.\n\nPor favor, descárgalo en la sección de Descargas.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      );
                    }

                    return ScoreImageView(
                      instrument: widget.instrument.path,
                      fileName: song.melodyFileName,
                      onTap: () {}, // En modo live mostramos la partitura fija
                    );
                  },
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