import 'dart:convert';
import 'package:audio_console_manager/models/role.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RolesRepository {
  static const _rolesKey = 'roles';

  // Roles predefinidos
  static List<Role> defaultRoles = [
    Role(name: 'Transmisión', busIndex: 1, visibleChannels: List.generate(8, (i) => i)),
    Role(name: 'Monitor', busIndex: 2, visibleChannels: List.generate(8, (i) => i)),
    Role(name: 'Main', busIndex: 0, visibleChannels: List.generate(8, (i) => i)),
  ];

  static Future<List<Role>> loadRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_rolesKey);
    if (jsonString == null) {
      return List<Role>.from(defaultRoles);
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Role.fromJson(e)).toList();
  }

  static Future<void> saveRoles(List<Role> roles) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(roles.map((e) => e.toJson()).toList());
    await prefs.setString(_rolesKey, jsonString);
  }
}
