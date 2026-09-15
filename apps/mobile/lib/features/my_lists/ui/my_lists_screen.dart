import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/services/instruments_service.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/models/instrument.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';
import 'package:new_symphony/features/my_lists/providers/my_lists_provider.dart';
import 'package:new_symphony/features/my_lists/ui/qr_scanner_screen.dart';

import 'my_list_detail_screen.dart';

class MyListsScreen extends ConsumerWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(myListsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Listas'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'scan_qr',
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              tooltip: 'Escanear lista',
              onPressed: () async {
                final raw = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                );
                if (raw == null) return;

                final payload = _parseQrPayload(raw);
                if (payload == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('QR no valido para listas de Symphony')),
                  );
                  return;
                }

                if (!context.mounted) return;
                _showQrPreviewDialog(context, ref, payload);
              },
              child: const Icon(Icons.document_scanner),
            ),
            FloatingActionButton(
              heroTag: 'create_list',
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              onPressed: () => _showCreateListDialog(context, ref),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      body: lists.isEmpty
          ? const Center(child: Text('No tienes listas creadas aún'))
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingSmall),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                final instrumentName = getIt<InstrumentsService>().instruments()
                    .firstWhere(
                      (i) => i.path == list.instrument, 
                      orElse: () => Instrument(
                        id: 0, 
                        name: list.instrument, 
                        path: list.instrument, 
                        iconPath: '',
                      ),
                    )
                    .name;

                return _SlidableListItem(
                  listId: list.id,
                  name: list.name,
                  instrumentName: instrumentName,
                  songCount: list.songTitles.length,
                  onEdit: () => _showRenameDialog(context, ref, list.id, list.name),
                  onDelete: () => ref.read(myListsProvider.notifier).deleteList(list.id),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyListDetailScreen(listId: list.id)),
                  ),
                );
              },
            ),
    );
  }

  _QrPayload? _parseQrPayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final version = decoded['v'];
      final name = decoded['n'];
      final songs = decoded['s'];

      if (version != 1) return null;
      if (name is! String || name.trim().isEmpty) return null;
      if (songs is! List) return null;

      final songTitles = songs.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (songTitles.isEmpty) return null;

      return _QrPayload(name: name.trim(), songTitles: songTitles);
    } catch (_) {
      return null;
    }
  }

  void _showQrPreviewDialog(BuildContext context, WidgetRef ref, _QrPayload payload) {
    String? selectedInstrument;
    final instruments = getIt<InstrumentsService>().instruments();
    final nameController = TextEditingController(text: payload.name);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lista detectada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la lista'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Text('${payload.songTitles.length} cantos'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedInstrument,
                items: instruments
                    .map((i) => DropdownMenuItem(value: i.path, child: Text(i.name)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedInstrument = val),
                decoration: const InputDecoration(labelText: 'Instrumento'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedInstrument == null
                  ? null
                  : () async {
                      final notifier = ref.read(myListsProvider.notifier);
                      final scoreRepo = getIt<ScoreRepository>();
                      final editedName = nameController.text.trim();

                      if (editedName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Escribe un nombre para la lista')),
                        );
                        return;
                      }

                      final downloadedFiles = scoreRepo.getDownloadedFilesByInstrument(selectedInstrument!);

                      final downloadedByNormalized = <String, String>{
                        for (final file in downloadedFiles)
                          scoreRepo.normalizeTitle(_displayTitleFromFileName(file.fileName, selectedInstrument!)):
                              _displayTitleFromFileName(file.fileName, selectedInstrument!),
                      };

                      final importableTitles = <String>[];
                      final missingTitles = <String>[];
                      for (final qrTitle in payload.songTitles) {
                        final normalized = scoreRepo.normalizeTitle(qrTitle);
                        final localTitle = downloadedByNormalized[normalized];
                        if (localTitle != null) {
                          importableTitles.add(localTitle);
                        } else {
                          missingTitles.add(qrTitle);
                        }
                      }

                      if (importableTitles.isEmpty) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo importar la lista porque sus cantos no estan descargados'),
                          ),
                        );
                        return;
                      }

                      final beforeIds = ref.read(myListsProvider).map((l) => l.id).toSet();

                      final importedName = _buildImportedListName(editedName, notifier);
                      notifier.createList(importedName, selectedInstrument!);

                      final listsAfterCreate = ref.read(myListsProvider);
                      final importedList = listsAfterCreate.firstWhere(
                        (l) => !beforeIds.contains(l.id),
                        orElse: () => listsAfterCreate.last,
                      );

                      notifier.addSongsToList(importedList.id, importableTitles);

                      if (!context.mounted) return;
                      Navigator.pop(context);

                      if (missingTitles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lista "${importedList.name}" importada')),
                        );
                        return;
                      }

                      final preview = missingTitles.take(3).join(', ');
                      final suffix = missingTitles.length > 3 ? '...' : '';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Lista importada con ${importableTitles.length} cantos. Omitidos: $preview$suffix',
                          ),
                        ),
                      );
                    },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  String _buildImportedListName(String baseName, MyListsNotifier notifier) {
    final trimmed = baseName.trim();
    if (notifier.isNameAvailable(trimmed)) return trimmed;

    var index = 1;
    var candidate = '$trimmed (importada)';
    while (!notifier.isNameAvailable(candidate)) {
      index++;
      candidate = '$trimmed (importada $index)';
    }
    return candidate;
  }

  String _displayTitleFromFileName(String fileName, String instrumentPath) {
    var baseName = fileName.replaceAll('.png', '');
    final arrangementSuffix = '_$instrumentPath';
    if (baseName.endsWith(arrangementSuffix)) {
      baseName = baseName.substring(0, baseName.length - arrangementSuffix.length);
    }

    return baseName
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  void _showCreateListDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(myListsProvider.notifier);
    final nameController = TextEditingController(text: notifier.generateDefaultName());
    String? selectedInstrument;
    final instruments = getIt<InstrumentsService>().instruments();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva Lista'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la lista'),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedInstrument,
                items: instruments.map((i) => DropdownMenuItem(
                  value: i.path,
                  child: Text(i.name),
                )).toList(),
                onChanged: (val) => setDialogState(() => selectedInstrument = val),
                decoration: const InputDecoration(labelText: 'Instrumento'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                
                if (!notifier.isNameAvailable(name)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ya existe una lista con este nombre')),
                  );
                  return;
                }

                if (selectedInstrument != null) {
                  notifier.createList(name, selectedInstrument!);
                  Navigator.pop(context);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, String id, String currentName) {
    final notifier = ref.read(myListsProvider.notifier);
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar Lista'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nuevo nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                if (!notifier.isNameAvailable(name, excludeId: id)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Este nombre ya está en uso')),
                  );
                  return;
                }
                notifier.renameList(id, name);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _QrPayload {
  final String name;
  final List<String> songTitles;

  const _QrPayload({required this.name, required this.songTitles});
}

class _SlidableListItem extends StatefulWidget {
  final String listId;
  final String name;
  final String instrumentName;
  final int songCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SlidableListItem({
    required this.listId,
    required this.name,
    required this.instrumentName,
    required this.songCount,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_SlidableListItem> createState() => _SlidableListItemState();
}

class _SlidableListItemState extends State<_SlidableListItem> {
  double _offset = 0;
  static const double _actionWidth = 80;
  static const double _maxSlide = _actionWidth * 2;

  void _reset() => setState(() => _offset = 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: [
          // Fondo con botones (se revela al deslizar)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
              child: Container(
                color: Colors.transparent, // Quitamos el rojo global para evitar fugas en las esquinas
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        _reset();
                        widget.onEdit();
                      },
                      child: Container(
                        width: _actionWidth,
                        height: double.infinity,
                        color: AppColors.accent,
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _reset();
                        widget.onDelete();
                      },
                      child: Container(
                        width: _actionWidth,
                        height: double.infinity,
                        color: AppColors.error,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tarjeta Superior (la que se mueve)
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _offset += details.delta.dx;
                // Limitar el swipe solo a la izquierda y hasta el ancho de los botones
                if (_offset > 0) _offset = 0;
                if (_offset < -_maxSlide) _offset = -_maxSlide;
              });
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                // Snap effect: si pasó de la mitad de un botón, se queda abierto
                if (_offset < -(_actionWidth / 2)) {
                  _offset = -_maxSlide;
                } else {
                  _offset = 0;
                }
              });
            },
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: Card(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF313542): null,                
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
                  side: BorderSide(color: AppColors.grey.withOpacity(0.2)),
                ),
                child: ListTile(                  
                  leading: const Icon(Icons.playlist_play, color: AppColors.accent),
                  title: Text(
                    widget.name, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(
                    widget.instrumentName, 
                    style: const TextStyle(fontSize: 12, color: Colors.grey)
                  ),
                  trailing: Text('${widget.songCount} cantos'),
                  onTap: () {
                    if (_offset != 0) {
                      _reset();
                    } else {
                      widget.onTap();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}