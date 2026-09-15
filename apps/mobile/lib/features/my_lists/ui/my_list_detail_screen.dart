import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/features/my_lists/providers/my_lists_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';
import 'package:new_symphony/features/score/ui/score_screen.dart';
import 'package:new_symphony/core/services/instruments_service.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';
import 'package:new_symphony/features/practice/ui/widgets/song_picker_sheet.dart';

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
            icon: const Icon(Icons.qr_code),
            tooltip: 'Compartir lista',
            onPressed: () => _showQrDialog(context, myList.name, myList.songTitles),
          ),
        ],
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
                      leading: ChordAvatar(chord: chord),
                      title: Text(title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navegar al visor de partitura con el contexto de la lista
                        availableSongsAsync.whenData((allSongs) {
                          // Mapeamos sobre songTitles para preservar el orden en que el usuario 
                          // agregó los cantos a la lista, en lugar del orden alfabético de la DB.
                          final songsInList = myList.songTitles
                              .map((title) => allSongs.firstWhere((s) => s.title == title))
                              .toList();
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

  void _showQrDialog(BuildContext context, String name, List<String> songTitles) {
    final payload = jsonEncode({'v': 1, 'n': name, 's': songTitles});
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name, textAlign: TextAlign.center),
        content: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: AppColors.white,
              ),
              const SizedBox(height: 12),
              Text(
                '${songTitles.length} cantos',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAddSongPicker(BuildContext context, WidgetRef ref, String instrument, AsyncValue<List<PracticeSong>> songsAsync) {
    final myList = ref.read(myListsProvider).firstWhere((l) => l.id == listId);

    songsAsync.whenData((songs) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SongPickerSheet(
          songs: songs,
          initialSelectedTitles: myList.songTitles,
          instrumentPath: instrument,
          title: 'Agregar Cantos',
          onConfirm: (selectedTitles) {
            ref.read(myListsProvider.notifier).addSongsToList(listId, selectedTitles);
          },
        ),
      );
    });
  }
}