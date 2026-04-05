import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
import 'package:new_symphony/features/score/ui/score_screen.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';

class PracticeLibraryScreen extends ConsumerStatefulWidget {
  final Instrument instrument;
  const PracticeLibraryScreen({super.key, required this.instrument});

  @override
  ConsumerState<PracticeLibraryScreen> createState() => _PracticeLibraryScreenState();
}

class _PracticeLibraryScreenState extends ConsumerState<PracticeLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedChord;
  final List<String> _chordOptions = ["C", "Eb", "F", "G", "Bb"];

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
            child: Row(              
              children: [
                ChoiceChip(
                  label: const Text("Todos"),
                  selected: _selectedChord == null,
                  onSelected: (val) => setState(() => _selectedChord = null),
                ),
                ..._chordOptions.map((chord) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(chord),
                    selected: _selectedChord == chord,
                    onSelected: (val) => setState(() => _selectedChord = val ? chord : null),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: songsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (songs) {
                // Aplicamos el filtro de tonalidad sobre los resultados
                final filteredSongs = _selectedChord == null 
                    ? songs 
                    : songs.where((s) {
                        final chord = getIt<ScoreRepository>().getChordForSongSync(s.title, widget.instrument.path);
                        return chord == _selectedChord;
                      }).toList();

                if (filteredSongs.isEmpty) {
                  return const Center(
                    child: Text('No hay partituras descargadas para este instrumento.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];
                    final chord = getIt<ScoreRepository>().getChordForSongSync(song.title, widget.instrument.path);
                    
                    return Card(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightGrey.withOpacity(0.1): null,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                        side: BorderSide(color: AppColors.grey.withOpacity(0.2)),
                      ),
                      child: ListTile(
                        leading: _ChordAvatar(chord: chord),
                        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          song.hasArrangementDownloaded ? 'Melodía y Arreglo' : 'Solo Melodía',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScoreScreen(
                                instrument: widget.instrument,
                                songs: filteredSongs,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
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
}

class _ChordAvatar extends StatelessWidget {
  final String chord;
  const _ChordAvatar({required this.chord});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
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
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}