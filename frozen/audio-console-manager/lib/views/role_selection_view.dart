import 'package:audio_console_manager/models/role.dart';
import 'package:audio_console_manager/models/roles_repository.dart';
import 'package:flutter/material.dart';
import 'package:audio_console_manager/views/role_edit_view.dart';

class RoleSelectionView extends StatefulWidget {
  final void Function(Role) onRoleSelected;
  const RoleSelectionView({super.key, required this.onRoleSelected});

  @override
  State<RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<RoleSelectionView> {
  List<Role> roles = [];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    roles = await RolesRepository.loadRoles();
    setState(() {});
  }

  Future<void> _saveRoles() async {
    await RolesRepository.saveRoles(roles);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un rol'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar rol',
            onPressed: () async {
              final newRole = await Navigator.push<Role>(
                context,
                MaterialPageRoute(
                  builder: (context) => RoleEditView(
                    buses: ['Main LR', ...List.generate(16, (i) => 'Bus ${i + 1}')],
                    channelCount: 8,
                    onSave: (role) {
                      Navigator.pop(context, role);
                    },
                  ),
                ),
              );
              if (newRole != null) {
                setState(() {
                  roles.add(newRole);
                });
                await _saveRoles();
              }
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: roles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final role = roles[i];
          return ListTile(
            title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Bus: ${role.busIndex == 0 ? 'Main LR' : 'Bus ${role.busIndex}'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar rol',
                  onPressed: () async {
                    final editedRole = await Navigator.push<Role>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoleEditView(
                          initialRole: role,
                          buses: ['Main LR', ...List.generate(16, (i) => 'Bus ${i + 1}')],
                          channelCount: 8,
                          onSave: (updatedRole) {},
                          onDelete: () {
                            Navigator.pop(context, null);
                          },
                        ),
                      ),
                    );
                    setState(() {
                      if (editedRole == null) {
                        // Solo eliminar si se presionó el botón de eliminar
                        // (agregar una bandera especial si es necesario)
                        // Por ahora, NO eliminar si es null (solo cancelar)
                        // roles.removeAt(i);
                      } else {
                        roles[i] = editedRole;
                      }
                    });
                    await _saveRoles();
                  },
                ),
                const Icon(Icons.arrow_forward_ios),
              ],
            ),
            onTap: () => widget.onRoleSelected(role),
          );
        },
      ),
    );
  }
}
