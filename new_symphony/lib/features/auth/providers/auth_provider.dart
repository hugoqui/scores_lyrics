import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/services/service_locator.dart';
import 'package:new_symphony/data/repositories/auth_repository.dart';
import 'package:new_symphony/core/utils/device_utils.dart';

/// Provider que maneja el estado de la autenticación (Cargando, Error o Éxito)
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(getIt<AuthRepository>());
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      // Obtenemos el ID del dispositivo de forma nativa
      final deviceId = await DeviceUtils.getDeviceId();
      
      await _repository.login(email, password, deviceId);
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}