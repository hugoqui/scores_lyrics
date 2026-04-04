import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';
import 'package:new_symphony/core/services/instruments_service.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/features/my_lists/providers/my_lists_provider.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateListDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: lists.isEmpty
          ? const Center(child: Text('No tienes listas creadas aún'))
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingSmall),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return Dismissible(
                  key: Key(list.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(myListsProvider.notifier).deleteList(list.id);
                  },
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.playlist_play, color: AppColors.accent),
                      title: Text(list.name),
                      subtitle: Text('Instrumento: ${list.instrument} • ${list.songTitles.length} cantos'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MyListDetailScreen(listId: list.id)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showRenameDialog(context, ref, list.id, list.name),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCreateListDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedInstrument != null) {
                  ref.read(myListsProvider.notifier).createList(nameController.text, selectedInstrument!);
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
              if (controller.text.isNotEmpty) {
                ref.read(myListsProvider.notifier).renameList(id, controller.text);
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