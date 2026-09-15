import 'dart:async';

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
  ConsumerState<PracticeLibraryScreen> createState() =>
      _PracticeLibraryScreenState();
}

class _PracticeLibraryScreenState extends ConsumerState<PracticeLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  String? _selectedChord;
  final List<String> _chordOptions = ["C", "Eb", "F", "G", "Bb"];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsState = ref.watch(practiceSongsProvider(widget.instrument.path));

    return Scaffold(
      appBar: AppBar(title: Text('Práctica: ${widget.instrument.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en mi biblioteca...',
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
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() => _searchQuery = value);
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("Todos"),
                  selected: _selectedChord == null,
                  onSelected: (val) => setState(() => _selectedChord = null),
                ),
                ..._chordOptions.map(
                  (chord) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(chord),
                      selected: _selectedChord == chord,
                      onSelected: (val) =>
                          setState(() => _selectedChord = val ? chord : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: songsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (songs) {
                final scoreRepo = getIt<ScoreRepository>();

                // 1. Pre-procesamos la data para no calcular normalizaciones ni acordes en cada rebuild
                final songViewModels = songs.map((s) {
                  return (
                    song: s,
                    normalizedTitle: scoreRepo.normalizeTitle(s.title),
                    chord: scoreRepo.getChordForSongSync(
                      s.title,
                      widget.instrument.path,
                    ),
                  );
                }).toList();

                final normalizedQuery = scoreRepo.normalizeTitle(_searchQuery);

                // 2. Primero, filtramos solo por acorde para la lista de navegación
                final chordFilteredViewModels = songViewModels.where((vm) {
                  final matchesChord =
                      _selectedChord == null || vm.chord == _selectedChord;
                  return matchesChord;
                }).toList();

                // 3. Luego, filtramos por búsqueda para la lista que se muestra en pantalla
                final displayViewModels = chordFilteredViewModels.where((vm) {
                  final matchesSearch = vm.normalizedTitle.contains(
                    normalizedQuery,
                  );
                  return matchesSearch;
                }).toList();

                if (displayViewModels.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay partituras descargadas para este instrumento.',
                    ),
                  );
                }

                // La lista para el navegador solo debe estar filtrada por acorde, no por búsqueda
                final songsForNavigator = chordFilteredViewModels
                    .map((v) => v.song)
                    .toList();

                // Pre-calculamos el índice de cada canto en la lista de navegación (O(1) por fila)
                final navigatorIndexByTitle = <String, int>{
                  for (var i = 0; i < songsForNavigator.length; i++)
                    songsForNavigator[i].title: i,
                };

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMedium,
                  ),
                  itemCount: displayViewModels.length,
                  itemBuilder: (context, index) {
                    final vm =
                        displayViewModels[index]; // El ViewModel actual que se muestra
                    final song = vm.song;

                    final actualIndexInNavigatorList =
                        navigatorIndexByTitle[song.title] ?? 0;

                    return Card(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.lightGrey.withOpacity(0.1)
                          : null,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMedium,
                        ),
                        side: BorderSide(
                          color: AppColors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: ListTile(
                        leading: _ChordAvatar(chord: vm.chord),
                        title: Text(
                          song.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          song.hasArrangementDownloaded
                              ? 'Melodía y Arreglo'
                              : 'Solo Melodía',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScoreScreen(
                                instrument: widget.instrument,
                                songs: songsForNavigator,
                                initialIndex: actualIndexInNavigatorList,
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
