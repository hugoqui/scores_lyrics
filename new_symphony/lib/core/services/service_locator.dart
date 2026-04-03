import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_symphony/core/services/migration_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  // Servicios
  getIt.registerLazySingleton<MigrationService>(() => MigrationService(getIt<SharedPreferences>()));

  // Repositorios (Próximo paso)
}