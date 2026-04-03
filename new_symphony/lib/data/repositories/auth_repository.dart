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
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  bool isLoggedIn() => _prefs.getString('token') != null;
}