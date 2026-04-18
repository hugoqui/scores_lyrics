import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';

class SongPickerSheet extends StatefulWidget {
  final List<PracticeSong> songs;
  final List<String> initialSelectedTitles;
  final String instrumentPath;
  final String title;
  final Function(List<String>) onConfirm;

  const SongPickerSheet({
    super.key,
    required this.songs,
    required this.initialSelectedTitles,
    required this.instrumentPath,
    required this.title,
    required this.onConfirm,
  });

  @override
  State<SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<SongPickerSheet> {
  late List<String> _selectedTitles;
  String _searchQuery = "";
  String? _selectedChord;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedTitles = List.from(widget.initialSelectedTitles);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u');

  @override
  Widget build(BuildContext context) {
    final filteredSongs = widget.songs.where((s) {
      final matchesSearch = _normalize(s.title).contains(_normalize(_searchQuery));
      final currentChord = getIt<ScoreRepository>().getChordForSongSync(s.title, widget.instrumentPath);
      final matchesChord = _selectedChord == null || currentChord == _selectedChord;
      return matchesSearch && matchesChord;
    }).toList();

    final chordOptions = ["C", "Eb", "F", "G", "Bb"];

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.borderRadiusLarge)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: _selectedTitles.isEmpty 
                      ? null 
                      : () {
                          widget.onConfirm(_selectedTitles);
                          Navigator.pop(context);
                        },
                    child: Text('Confirmar (${_selectedTitles.length})'),
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
                onChanged: (val) {
                  if (_debounce?.isActive ?? false) _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    setState(() => _searchQuery = val);
                  });
                },
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
                    selected: _selectedChord == null,
                    onSelected: (val) => setState(() => _selectedChord = null),
                  ),
                  ...chordOptions.map((chord) => Padding(
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
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filteredSongs.length,
                itemBuilder: (context, index) {
                  final song = filteredSongs[index];
                  final isSelected = _selectedTitles.any((t) => _normalize(t) == _normalize(song.title));
                  final chord = getIt<ScoreRepository>().getChordForSongSync(song.title, widget.instrumentPath);

                  return CheckboxListTile(
                    secondary: ChordAvatar(chord: chord),
                    title: Text(song.title),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (!isSelected) _selectedTitles.add(song.title);
                        } else {
                          _selectedTitles.removeWhere((t) => _normalize(t) == _normalize(song.title));
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChordAvatar extends StatelessWidget {
  final String chord;
  const ChordAvatar({super.key, required this.chord});

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