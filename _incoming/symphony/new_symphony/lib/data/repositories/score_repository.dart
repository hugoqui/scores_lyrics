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
  Map<String, String> _chordMap = {}; // Caché de títulos normalizados -> acorde

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
    _loadApiSongsCache();
    // Si el caché está vacío (ej. primer inicio o error), intentamos descargar la lista de inmediato
    if (_apiSongs.isEmpty) {
      fetchApiSongs();
    }
  }

  void _loadApiSongsCache() {
    final String? cachedData = _prefs.getString('api_songs_cache');
    if (cachedData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedData);
        _apiSongs = decoded.map((json) => ApiSong.fromJson(json)).toList();
        _updateChordMap();
      } catch (e) {
        print('Error loading API songs cache: $e');
      }
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

  List<DownloadedFile> get downloadedFiles => List.unmodifiable(_downloadedFiles);

  void addDownloadedFile(DownloadedFile file) {
    // Evitamos duplicados: si ya existe, lo quitamos antes de insertar el nuevo
    _downloadedFiles.removeWhere((f) => f.fileName == file.fileName && f.instrument == file.instrument);
    _downloadedFiles.add(file);
    _saveToNewStorage();
  }

  /// Elimina del almacenamiento local todos los archivos descargados para un instrumento
  /// y limpia sus registros en almacenamiento persistente.
  Future<void> clearDownloadedFilesByInstrument(String instrument) async {
    final directory = await getApplicationDocumentsDirectory();
    final instrumentPath = '${directory.path}/$instrument';
    final folder = Directory(instrumentPath);

    if (await folder.exists()) {
      final entries = await folder.list().toList();
      for (final entry in entries) {
        if (entry is! File) continue;

        final pathLower = entry.path.toLowerCase();
        final isImage = pathLower.endsWith('.png') ||
            pathLower.endsWith('.jpg') ||
            pathLower.endsWith('.jpeg') ||
            pathLower.endsWith('.gif');
        if (!isImage) continue;

        try {
          await entry.delete();
        } catch (_) {}
      }
    }

    _downloadedFiles.removeWhere((f) => f.instrument == instrument);
    _saveToNewStorage();
  }

  List<DownloadedFile> getDownloadedFilesByInstrument(String instrument) {
    return _downloadedFiles.where((f) => f.instrument == instrument).toList();
  }

  void _updateChordMap() {
    final map = <String, String>{};
    for (var song in _apiSongs) {
      map[normalizeTitle(song.title)] = song.chord;
    }
    _chordMap = map;
  }

  /// Verifica si un archivo existe localmente basándose solo en su nombre e instrumento,
  /// ignorando si el acorde ha cambiado en el servidor.
  bool isFileDownloaded(String fileName, String instrument) {
    // 1. Verificación exacta por nombre de archivo
    if (_downloadedFiles.any((f) => f.fileName == fileName && f.instrument == instrument)) return true;

    // 2. Verificación por similitud de título (para manejar cambios de nombre en el servidor)
    final searchTitle = normalizeTitle(fileName.replaceAll('.png', ''));
    return _downloadedFiles.any((f) {
      if (f.instrument != instrument) return false;
      final localTitle = normalizeTitle(f.fileName.replaceAll('.png', ''));
      return localTitle.contains(searchTitle) || searchTitle.contains(localTitle);
    });
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
    try {
      final response = await _dio.get('https://api.iglesiacristianabelen.com/api/cantos');
      final List<dynamic> data = response.data;
      _apiSongs = data.map((json) => ApiSong.fromJson(json)).toList();
      _updateChordMap();
      
      // Guardamos en caché para que persista al cerrar la app
      _prefs.setString('api_songs_cache', jsonEncode(data));
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

  /// Limpia el texto de acentos, espacios y caracteres especiales para comparaciones seguras
  String normalizeTitle(String text) {
    String processed = text;
    
    // 1. Manejar codificación de URL (ej. %C3%B1 -> ñ)
    try {
      processed = Uri.decodeComponent(processed);
    } catch (_) {}

    // 2. Quitar extensión si existe
    processed = processed.replaceAll(RegExp(r'\.(png|jpe?g|gif|mp3)$', caseSensitive: false), '');

    return processed
        .toLowerCase()
        .trim()
        // 3. Normalizar 'ñ' tanto de Windows (NFC) como de Mac (NFD)
        .replaceAll('\u00f1', 'n')   // ñ precompuesta
        .replaceAll('n\u0303', 'n')   // n + tilde combinada
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Replica getSongChord: Busca la tonalidad en la lista de la API
  Future<String> getChordForSong(String fileName, String instrument) async {
    if (_apiSongs.isEmpty) await fetchApiSongs();
    // Reutilizamos la lógica optimizada O(1)
    return getChordForSongSync(fileName, instrument);
  }

  String getChordForSongSync(String title, String instrument) {
    final searchTitle = normalizeTitle(title);

    // 1. Búsqueda directa en el Map (O(1)) - Instantáneo
    if (_chordMap.containsKey(searchTitle)) return _chordMap[searchTitle]!;
    
    // 2. Coincidencia con sufijo de instrumento (ej. "Canto_piano")
    final instrumentSuffix = '_$instrument';
    if (searchTitle.endsWith(instrumentSuffix)) {
      final baseTitle = searchTitle.substring(0, searchTitle.length - instrumentSuffix.length);
      if (_chordMap.containsKey(baseTitle)) return _chordMap[baseTitle]!;
    }

    return 'F';
  }

  /// Verifica si un título existe en la base de datos de la API (caché)
  bool isValidSongTitle(String title) {
    // Búsqueda instantánea O(1) usando el mapa ya generado
    return _chordMap.containsKey(normalizeTitle(title));
  }
}