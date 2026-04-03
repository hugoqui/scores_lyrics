import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_symphony/data/models/auth_response.dart';

class AuthRepository {
  final Dio _dio;
  final SharedPreferences _prefs;

  AuthRepository(this._dio, this._prefs);

  Future<AuthResponse> login(String email, String password, String deviceId) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
        'device': deviceId,
      });

      final authResponse = AuthResponse.fromJson(response.data);
      await _prefs.setString('token', authResponse.token);
      // Guardar email y password para "recordarme"
      await _prefs.setString('saved_email', email);
      await _prefs.setString('saved_password', password);
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  bool isLoggedIn() => _prefs.getString('token') != null;

  String? getSavedEmail() {
    return _prefs.getString('saved_email');
  }

  String? getSavedPassword() {
    return _prefs.getString('saved_password');
  }

  /// Elimina las credenciales guardadas y el token de sesión
  Future<void> clearSavedCredentials() async {
    await _prefs.remove('saved_email');
    await _prefs.remove('saved_password');
  }
}