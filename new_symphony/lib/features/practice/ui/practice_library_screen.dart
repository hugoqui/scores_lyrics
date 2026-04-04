import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
import 'package:new_symphony/features/score/ui/score_screen.dart';

class PracticeLibraryScreen extends ConsumerStatefulWidget {
  final Instrument instrument;
  const PracticeLibraryScreen({super.key, required this.instrument});

  @override
  ConsumerState<PracticeLibraryScreen> createState() => _PracticeLibraryScreenState();
}

class _PracticeLibraryScreenState extends ConsumerState<PracticeLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsState = ref.watch(practiceSongsProvider(widget.instrument.path));

    return Scaffold(
      appBar: AppBar(
        title: Text('Práctica: ${widget.instrument.name}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en mi biblioteca...',
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => ref.read(practiceSongsProvider(widget.instrument.path).notifier).filterSongs(value),
            ),
          ),
          Expanded(
            child: songsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (songs) {
                if (songs.isEmpty) {
                  return const Center(
                    child: Text('No hay partituras descargadas para este instrumento.'),
                  );
                }
                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      title: Text(song.title),
                      subtitle: Text(song.hasArrangementDownloaded ? 'Melodía y Arreglo' : 'Solo Melodía'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScoreScreen(
                              instrument: widget.instrument,
                              songs: songs,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
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
}