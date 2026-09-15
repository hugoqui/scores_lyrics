import 'package:audio_console_manager/views/connection_view.dart';
import 'package:flutter/material.dart';
import 'package:audio_console_manager/theme/theme.dart';
import 'package:audio_console_manager/views/role_selection_view.dart';
import 'package:audio_console_manager/models/role.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Console Manager',
      theme: AppTheme.darkTheme,
      home: RoleSelectionFlow(),
    );
  }
}

class RoleSelectionFlow extends StatefulWidget {
  const RoleSelectionFlow({super.key});

  @override
  State<RoleSelectionFlow> createState() => _RoleSelectionFlowState();
}

class _RoleSelectionFlowState extends State<RoleSelectionFlow> {
  Role? _selectedRole;

  @override
  Widget build(BuildContext context) {
    if (_selectedRole == null) {
      return RoleSelectionView(
        onRoleSelected: (role) {
          setState(() {
            _selectedRole = role;
          });
        },
      );
    } else {
      return ConnectionView(
        selectedRole: _selectedRole!,
        onLogout: () {
          setState(() {
            _selectedRole = null;
          });
        },
      );
    }
  }
}
