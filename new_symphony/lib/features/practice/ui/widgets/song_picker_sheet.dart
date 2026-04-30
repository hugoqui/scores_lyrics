import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';
import 'package:new_symphony/features/practice/providers/practice_provider.dart';

// Define un ViewModel para agrupar los datos pre-procesados de cada canción
typedef SongViewModel = ({
  PracticeSong song,
  String normalizedTitle,
  String chord,
});

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
  final FocusNode _searchFocusNode = FocusNode();

  late List<SongViewModel> _allSongViewModels;
  late List<SongViewModel> _filteredViewModels;
  late Set<String> _normalizedSelectedTitles;

  @override
  void initState() {
    super.initState();
    _selectedTitles = List.from(widget.initialSelectedTitles);

    final scoreRepo = getIt<ScoreRepository>();

    // 1. Pre-procesamos la data una sola vez al iniciar para evitar lag en el build
    _allSongViewModels = widget.songs.map((s) {
      return (
        song: s,
        normalizedTitle: scoreRepo.normalizeTitle(s.title),
        chord: scoreRepo.getChordForSongSync(s.title, widget.instrumentPath),
      );
    }).toList();

    _normalizedSelectedTitles = _selectedTitles.map((t) => scoreRepo.normalizeTitle(t)).toSet();
    
    _filterSongs();

    // 2. Auto-enfocar el teclado al abrir el modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterSongs() {
    final scoreRepo = getIt<ScoreRepository>();
    final normalizedQuery = scoreRepo.normalizeTitle(_searchQuery);

    _filteredViewModels = _allSongViewModels.where((vm) {
      final matchesSearch = vm.normalizedTitle.contains(normalizedQuery);
      final matchesChord = _selectedChord == null || vm.chord == _selectedChord;
      return matchesSearch && matchesChord;
    }).toList();
  }

  void _updateSelectedTitles(String title, bool? isSelected) {
    final scoreRepo = getIt<ScoreRepository>();
    final normalizedTitle = scoreRepo.normalizeTitle(title);

    setState(() {
      if (isSelected == true) {
        if (!_normalizedSelectedTitles.contains(normalizedTitle)) {
          _selectedTitles.add(title);
          _normalizedSelectedTitles.add(normalizedTitle);
        }
      } else {
        if (_normalizedSelectedTitles.contains(normalizedTitle)) {
          _selectedTitles.removeWhere((t) => scoreRepo.normalizeTitle(t) == normalizedTitle);
          _normalizedSelectedTitles.remove(normalizedTitle);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                focusNode: _searchFocusNode, // Asignar el FocusNode
                decoration: InputDecoration(
                  hintText: 'Buscar canto...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _debounce?.cancel();
                            setState(() {
                              _searchQuery = '';
                              _filterSongs(); // Volver a filtrar después de limpiar
                            });
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) {
                  if (_debounce?.isActive ?? false) _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() {
                      _searchQuery = val;
                      _filterSongs(); // Volver a filtrar después del debounce
                    });
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
                    onSelected: (val) => setState(() {
                      _selectedChord = null;
                      _filterSongs(); // Volver a filtrar después de cambiar el acorde
                    }),
                  ),
                  ...chordOptions.map((chord) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(chord),
                          selected: _selectedChord == chord,
                          onSelected: (val) => setState(() {
                            _selectedChord = val ? chord : null;
                            _filterSongs(); // Volver a filtrar después de cambiar el acorde
                          }),
                        ),
                      )),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredViewModels.length, // Usar la lista ya filtrada
                itemBuilder: (context, index) {
                  final vm = _filteredViewModels[index];
                  final song = vm.song;
                  final isSelected = _normalizedSelectedTitles.contains(vm.normalizedTitle); // Búsqueda O(1)

                  return CheckboxListTile(
                    secondary: ChordAvatar(chord: vm.chord),
                    title: Text(song.title),
                    value: isSelected,
                    onChanged: (val) => _updateSelectedTitles(song.title, val), // Usar el método helper
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