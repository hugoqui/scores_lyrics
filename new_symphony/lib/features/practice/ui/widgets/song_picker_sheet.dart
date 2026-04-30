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
  final TextEditingController _searchController = TextEditingController();
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
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scoreRepo = getIt<ScoreRepository>();

    // 1. Pre-procesamos la data para no calcular normalizaciones ni acordes en cada rebuild
    final songViewModels = widget.songs.map((s) {
      return (
        song: s,
        normalizedTitle: scoreRepo.normalizeTitle(s.title),
        chord: scoreRepo.getChordForSongSync(s.title, widget.instrumentPath),
      );
    }).toList();

    final normalizedQuery = scoreRepo.normalizeTitle(_searchQuery);
    final normalizedSelected = _selectedTitles.map((t) => scoreRepo.normalizeTitle(t)).toSet();

    // 2. Filtramos sobre el ViewModel ya procesado
    final filteredViewModels = songViewModels.where((vm) {
      final matchesSearch = vm.normalizedTitle.contains(normalizedQuery);
      final matchesChord = _selectedChord == null || vm.chord == _selectedChord;
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
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar canto...',
                  prefixIcon: const Icon(Icons.search),
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
                onChanged: (val) {
                  if (_debounce?.isActive ?? false) _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
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
                itemCount: filteredViewModels.length,
                itemBuilder: (context, index) {
                  final vm = filteredViewModels[index];
                  final song = vm.song;
                  // Búsqueda O(1) en el Set de normalizados
                  final isSelected = normalizedSelected.contains(vm.normalizedTitle);

                  return CheckboxListTile(
                    secondary: ChordAvatar(chord: vm.chord),
                    title: Text(song.title),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (!isSelected) _selectedTitles.add(song.title);
                        } else {
                          _selectedTitles.removeWhere((t) => scoreRepo.normalizeTitle(t) == vm.normalizedTitle);
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