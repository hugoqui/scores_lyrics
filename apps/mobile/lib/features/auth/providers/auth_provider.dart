import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/repositories/auth_repository.dart';
import 'package:new_symphony/core/utils/device_utils.dart';

class AuthState {
  final AsyncValue<void> loginStatus;
  final String? savedEmail;
  final String? savedPassword;

  AuthState({required this.loginStatus, this.savedEmail, this.savedPassword});
}

/// Provider que maneja el estado de la autenticación (Cargando, Error o Éxito)
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(getIt<AuthRepository>());
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState(
    loginStatus: const AsyncValue.data(null),
    savedEmail: _repository.getSavedEmail(),
    savedPassword: _repository.getSavedPassword(),
  ));

  Future<void> login(String email, String password) async {
    state = AuthState(loginStatus: const AsyncValue.loading(), savedEmail: state.savedEmail, savedPassword: state.savedPassword);
    
    try {
      // Obtenemos el ID del dispositivo de forma nativa
      final deviceId = await DeviceUtils.getDeviceId();
      
      await _repository.login(email, password, deviceId);
      
      state = AuthState(loginStatus: const AsyncValue.data(null), savedEmail: email, savedPassword: password);
    } catch (e, stack) {
      state = AuthState(loginStatus: AsyncValue.error(e, stack), savedEmail: state.savedEmail, savedPassword: state.savedPassword);
    }
  }

  void loadSavedCredentials() {
    final savedEmail = _repository.getSavedEmail();
    final savedPassword = _repository.getSavedPassword();
    state = AuthState(loginStatus: const AsyncValue.data(null), savedEmail: savedEmail, savedPassword: savedPassword);
  }

  bool isLoggedIn() {
    return _repository.isLoggedIn();
  }

  // Método para limpiar las credenciales guardadas (ej. al cerrar sesión)
  Future<void> clearSavedCredentials() async {
    await _repository.clearSavedCredentials();
    state = AuthState(loginStatus: const AsyncValue.data(null), savedEmail: null, savedPassword: null);
  }
}