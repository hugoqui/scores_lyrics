import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/features/my_lists/providers/my_lists_provider.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
import 'package:new_symphony/features/score/ui/score_screen.dart';
import 'package:new_symphony/core/services/instruments_service.dart';
import 'package:new_symphony/core/services/service_locator.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddSongPicker(context, ref, myList.instrument, availableSongsAsync),
          ),
        ],
      ),
      body: myList.songTitles.isEmpty
          ? const Center(child: Text('La lista está vacía'))
          : ListView.builder(
              itemCount: myList.songTitles.length,
              itemBuilder: (context, index) {
                final title = myList.songTitles[index];
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
                  child: ListTile(
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
                );
              },
            ),
    );
  }

  void _showAddSongPicker(BuildContext context, WidgetRef ref, String instrument, AsyncValue<List<PracticeSong>> songsAsync) {
    songsAsync.whenData((songs) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Agregar a la lista', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return ListTile(
                    title: Text(song.title),
                    onTap: () {
                      ref.read(myListsProvider.notifier).addSongToList(listId, song.title);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}