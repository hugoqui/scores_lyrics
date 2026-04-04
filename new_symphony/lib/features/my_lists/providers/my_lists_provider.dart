import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/data/models/my_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_symphony/core/services/service_locator.dart';

class MyListsNotifier extends StateNotifier<List<MyList>> {
  final SharedPreferences _prefs;
  static const String _storageKey = 'my_lists_data_v1';

  MyListsNotifier(this._prefs) : super([]) {
    _loadLists();
  }

  void _loadLists() {
    final String? data = _prefs.getString(_storageKey);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        state = decoded.map((item) => MyList.fromJson(item)).toList();
      } catch (e) {
        state = [];
      }
    }
  }

  void _saveLists() {
    final String encoded = jsonEncode(state.map((l) => l.toJson()).toList());
    _prefs.setString(_storageKey, encoded);
  }

  void createList(String name, String instrument) {
    final newList = MyList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      instrument: instrument,
    );
    state = [...state, newList];
    _saveLists();
  }

  void renameList(String id, String newName) {
    state = [
      for (final list in state)
        if (list.id == id) list.copyWith(name: newName) else list
    ];
    _saveLists();
  }

  void deleteList(String id) {
    state = state.where((l) => l.id != id).toList();
    _saveLists();
  }

  void addSongToList(String listId, String songTitle) {
    state = [
      for (final list in state)
        if (list.id == listId && !list.songTitles.contains(songTitle))
          list.copyWith(songTitles: [...list.songTitles, songTitle])
        else
          list
    ];
    _saveLists();
  }

  void removeSongFromList(String listId, String songTitle) {
    state = [
      for (final list in state)
        if (list.id == listId)
          list.copyWith(
            songTitles: list.songTitles.where((t) => t != songTitle).toList(),
          )
        else
          list
    ];
    _saveLists();
  }
}

final myListsProvider = StateNotifierProvider<MyListsNotifier, List<MyList>>((ref) {
  return MyListsNotifier(getIt<SharedPreferences>());
});