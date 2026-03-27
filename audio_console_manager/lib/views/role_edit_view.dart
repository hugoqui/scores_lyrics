import 'package:audio_console_manager/models/role.dart';
import 'package:flutter/material.dart';

class RoleEditView extends StatefulWidget {
  final Role? initialRole;
  final void Function(Role) onSave;
  final void Function()? onDelete;
  final List<String> buses;
  final int channelCount;

  const RoleEditView({
    super.key,
    this.initialRole,
    required this.onSave,
    this.onDelete,
    required this.buses,
    required this.channelCount,
  });

  @override
  State<RoleEditView> createState() => _RoleEditViewState();
}

class _RoleEditViewState extends State<RoleEditView> {
  late TextEditingController _nameController;
  late int _selectedBus;
  late List<int> _selectedChannels;
  late List<int> _availableChannels;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialRole?.name ?? '',
    );
    _selectedBus = widget.initialRole?.busIndex ?? 0;
    _selectedChannels = List<int>.from(
      widget.initialRole?.visibleChannels ??
          List.generate(widget.channelCount, (i) => i),
    );
    _availableChannels = List.generate(
      widget.channelCount,
      (i) => i,
    ).where((i) => !_selectedChannels.contains(i)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialRole == null ? 'Nuevo Rol' : 'Editar Rol'),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Eliminar rol',
              onPressed: widget.onDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del rol'),
            ),
            const SizedBox(height: 16),
            Text('Bus asignado:', style: Theme.of(context).textTheme.bodyLarge),
            Wrap(
              spacing: 8,
              children: List.generate(
                widget.buses.length,
                (i) => ChoiceChip(
                  label: Text(widget.buses[i]),
                  selected: _selectedBus == i,
                  onSelected: (val) {
                    setState(() {
                      _selectedBus = i;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Canales visibles (arrastre para ordenar):',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  // Canales disponibles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Disponibles',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: ListView(
                            children: _availableChannels
                                .map(
                                  (ch) => ListTile(
                                    title: Text('Canal ${ch + 1}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.arrow_forward),
                                      onPressed: () {
                                        setState(() {
                                          _selectedChannels.add(ch);
                                          _availableChannels.remove(ch);
                                        });
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 24),
                  // Canales visibles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visibles',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: ReorderableListView(
                            buildDefaultDragHandles: true,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = _selectedChannels.removeAt(
                                  oldIndex,
                                );
                                _selectedChannels.insert(newIndex, item);
                              });
                            },
                            children: [
                              for (int i = 0; i < _selectedChannels.length; i++)
                                ListTile(
                                  key: ValueKey(_selectedChannels[i]),
                                  title: Text(
                                    'Canal ${_selectedChannels[i] + 1}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _availableChannels.add(
                                          _selectedChannels[i],
                                        );
                                        _selectedChannels.removeAt(i);
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // En tu ElevatedButton dentro de RoleEditView
                ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.trim().isEmpty ||
                        _selectedChannels.isEmpty)
                      return;

                    final role = Role(
                      name: _nameController.text.trim(),
                      busIndex:
                          _selectedBus, // Aquí ya se está usando el valor actualizado por el ChoiceChip
                      visibleChannels: List<int>.from(_selectedChannels),
                    );

                    // LLAMA A ONSAVE Y LUEGO CIERRA LA PANTALLA PASANDO EL ROL
                    widget.onSave(role);
                    Navigator.pop(context, role); // <--- ESTO ES LO QUE FALTA
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
