import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/features/my_lists/providers/my_lists_provider.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
import 'package:new_symphony/features/score/ui/score_screen.dart';
import 'package:new_symphony/core/services/instruments_service.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';

class MyListDetailScreen extends ConsumerWidget {
  final String listId;
  const MyListDetailScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myLists = ref.watch(myListsProvider);
    final myList = myLists.firstWhere((l) => l.id == listId);
    
    // Cargamos todos los cantos disponibles para ese instrumento
    final availableSongsAsync = ref.watch(practiceSongsProvider(myList.instrument));

    return Scaffold(
      appBar: AppBar(
        title: Text(myList.name),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        onPressed: () => _showAddSongPicker(context, ref, myList.instrument, availableSongsAsync),
        child: const Icon(Icons.add),
      ),
      body: myList.songTitles.isEmpty
          ? const Center(child: Text('La lista está vacía'))
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingSmall),
              itemCount: myList.songTitles.length,
              itemBuilder: (context, index) {
                final title = myList.songTitles[index];
                final chord = getIt<ScoreRepository>().getChordForSongSync(title, myList.instrument);

                return Dismissible(
                  key: Key('${listId}_$title'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.error,
                    child: const Icon(Icons.remove_circle, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(myListsProvider.notifier).removeSongFromList(listId, title);
                  },
                  child: Card(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF313542): null,                
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                      side: BorderSide(color: AppColors.grey.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      leading: _ChordAvatar(chord: chord),
                      title: Text(title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navegar al visor de partitura con el contexto de la lista
                        availableSongsAsync.whenData((allSongs) {
                          final songsInList = allSongs.where((s) => myList.songTitles.contains(s.title)).toList();
                          final songIndex = songsInList.indexWhere((s) => s.title == title);
                          
                          final instrumentObj = getIt<InstrumentsService>().instruments()
                              .firstWhere((i) => i.path == myList.instrument);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScoreScreen(
                                instrument: instrumentObj,
                                songs: songsInList,
                                initialIndex: songIndex,
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddSongPicker(BuildContext context, WidgetRef ref, String instrument, AsyncValue<List<PracticeSong>> songsAsync) {
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
              final currentChord = getIt<ScoreRepository>().getChordForSongSync(s.title, instrument);
              final matchesChord = selectedChord == null || currentChord == selectedChord;
              return matchesSearch && matchesChord;
            }).toList();

            final chordOptions = ["C", "Eb", "F", "G", "Bb"];

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text('Agregar Cantos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const Spacer(),
                        TextButton(
                          onPressed: selectedTitles.isEmpty ? null : () {
                            ref.read(myListsProvider.notifier).addSongsToList(listId, selectedTitles);
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
                        return CheckboxListTile(
                          secondary: _ChordAvatar(chord: getIt<ScoreRepository>().getChordForSongSync(song.title, instrument)),
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
            );
          },
        ),
      );
    });
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