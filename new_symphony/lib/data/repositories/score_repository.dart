import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_symphony/data/models/downloaded_file.dart';
import 'package:new_symphony/data/models/api_song.dart';
import 'package:new_symphony/core/services/migration_service.dart';

class ScoreRepository {
  final Dio _dio;
  final SharedPreferences _prefs;
  final MigrationService _migrationService;
  final String _scoresUrl = 'https://partituras.iglesiacristianabelen.com';
  
  List<DownloadedFile> _downloadedFiles = [];
  List<ApiSong> _apiSongs = [];

  ScoreRepository(this._dio, this._prefs, this._migrationService) {
    _init();
  }

  void _init() {
    // Script de Primer Inicio: Si no se ha migrado, cargamos lo que dejó NativeScript
    if (!_migrationService.isMigrated()) {
      _downloadedFiles = _migrationService.getLegacyDownloadedFiles();
      _saveToNewStorage();
      _prefs.setBool('flutter_migrated', true);
    } else {
      _loadFromStorage();
    }
  }

  void _loadFromStorage() {
    final String? data = _prefs.getString('downloaded_files_v2');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _downloadedFiles = decoded.map((item) => DownloadedFile.fromJson(item)).toList();
    }
  }

  void _saveToNewStorage() {
    final String encoded = jsonEncode(_downloadedFiles.map((f) => f.toJson()).toList());
    _prefs.setString('downloaded_files_v2', encoded);
  }

  void addDownloadedFile(DownloadedFile file) {
    // Evitamos duplicados: si ya existe, lo quitamos antes de insertar el nuevo
    _downloadedFiles.removeWhere((f) => f.fileName == file.fileName && f.instrument == file.instrument);
    _downloadedFiles.add(file);
    _saveToNewStorage();
  }

  List<DownloadedFile> getDownloadedFilesByInstrument(String instrument) {
    return _downloadedFiles.where((f) => f.instrument == instrument).toList();
  }

  /// Replica getFileNames: Parsea el HTML del listado de archivos
  Future<List<String>> fetchRemoteAvailableFiles(String instrument) async {
    try {
      final response = await _dio.get('$_scoresUrl/$instrument/', options: Options(responseType: ResponseType.plain));
      final html = response.data as String;
      
      final regex = RegExp(r'<a href="([^"]+)">');
      final matches = regex.allMatches(html);
      
      final List<String> files = [];
      for (final match in matches) {
        final fileName = Uri.decodeComponent(match.group(1)!);
        if (fileName != '../' && RegExp(r'\.(png|jpe?g|gif)$', caseSensitive: false).hasMatch(fileName)) {
          files.add(fileName);
        }
      }
      return files;
    } catch (e) {
      return [];
    }
  }

  /// Replica getDbSongs: Obtiene el JSON de cantos
  Future<void> fetchApiSongs() async {
    if (_apiSongs.isNotEmpty) return;
    try {
      final response = await _dio.get('https://api.iglesiacristianabelen.com/api/cantos');
      final List<dynamic> data = response.data;
      _apiSongs = data.map((json) => ApiSong.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching API songs: $e');
    }
  }

  /// Replica downloadFile: Descarga el binario y lo guarda en la carpeta del instrumento
  Future<String> downloadFile(String fileName, String instrument) async {
    try {
      final encodedFileName = Uri.encodeComponent(fileName);
      final url = '$_scoresUrl/$instrument/$encodedFileName';
      
      final directory = await getApplicationDocumentsDirectory();
      final instrumentPath = '${directory.path}/$instrument';
      final folder = Directory(instrumentPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // Manejo de caracteres especiales como en NS
      final sanitizedName = fileName.replaceAll('%E2%94%9C%E2%96%92', 'ñ');
      final filePath = '$instrumentPath/$sanitizedName';

      await _dio.download(url, filePath);
      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Replica getSongChord: Busca la tonalidad en la lista de la API
  Future<String> getChordForSong(String fileName, String instrument) async {
    await fetchApiSongs();
    final searchTitle = fileName.replaceAll('.png', '').toLowerCase();
    
    try {
      final song = _apiSongs.firstWhere((s) {
        final title = s.title.toLowerCase().replaceAll(' ', '_');
        return title == searchTitle || '${title}_$instrument' == searchTitle;
      });
      return song.chord;
    } catch (e) {
      return 'F';
    }
  }
}