import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  final SharedPreferences _prefs;

  DioClient(this._prefs);

  Dio get dio {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Obtenemos el host y el token dinámicamente de SharedPreferences
          // Agregamos la URL de tu API como valor por defecto para pruebas
          final host = _prefs.getString('host') ?? 'https://api.iglesiacristianabelen.com/api';
          final token = _prefs.getString('token');

          options.baseUrl = host;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    return dio;
  }
}