import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_symphony/data/models/downloaded_file.dart';

class MigrationService {
  final SharedPreferences _prefs;

  MigrationService(this._prefs);

  /// Recupera el host configurado en la app anterior
  String? getLegacyHost() {
    return _prefs.getString('host');
  }

  /// Recupera el token de sesión
  String? getLegacyToken() {
    return _prefs.getString('token');
  }

  /// Recupera la lista de archivos descargados por NativeScript
  List<DownloadedFile> getLegacyDownloadedFiles() {
    final String? filesJson = _prefs.getString('downloadedFiles');
    if (filesJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(filesJson);
      return decoded.map((item) => DownloadedFile.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Verifica si ya se realizó la migración inicial
  bool isMigrated() {
    return _prefs.getBool('flutter_migrated') ?? false;
  }
}