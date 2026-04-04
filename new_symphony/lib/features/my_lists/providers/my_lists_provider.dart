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

  String generateDefaultName() {
    int count = state.length + 1;
    String name = 'Lista $count';
    while (state.any((l) => l.name.toLowerCase() == name.toLowerCase())) {
      count++;
      name = 'Lista $count';
    }
    return name;
  }

  bool isNameAvailable(String name, {String? excludeId}) {
    return !state.any((l) => 
      l.name.toLowerCase() == name.trim().toLowerCase() && l.id != excludeId
    );
  }

  void createList(String name, String instrument) {
    final newList = MyList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      instrument: instrument,
    );
    state = [...state, newList];
    _saveLists();
  }

  void renameList(String id, String newName) {
    state = [
      for (final list in state)
        if (list.id == id) list.copyWith(name: newName.trim()) else list
    ];
    _saveLists();
  }

  void deleteList(String id) {
    state = state.where((l) => l.id != id).toList();
    _saveLists();
  }

  void addSongsToList(String listId, List<String> titles) {
    state = [
      for (final list in state)
        if (list.id == listId)
          list.copyWith(
            songTitles: {
              ...list.songTitles,
              ...titles,
            }.toList(),
          )
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