import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_symphony/core/services/migration_service.dart';
import 'package:new_symphony/core/services/instruments_service.dart';
import 'package:new_symphony/data/repositories/score_repository.dart';
import 'package:new_symphony/data/repositories/auth_repository.dart';
import 'package:new_symphony/core/network/dio_client.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  // Servicios
  getIt.registerLazySingleton<MigrationService>(() => MigrationService(getIt<SharedPreferences>()));
  getIt.registerLazySingleton<InstrumentsService>(() => InstrumentsService());
  
  // Network
  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt<SharedPreferences>()));
  getIt.registerLazySingleton<Dio>(() => getIt<DioClient>().dio);

  // Repositorios
  getIt.registerLazySingleton<ScoreRepository>(() => ScoreRepository(
    getIt<Dio>(),
    getIt<SharedPreferences>(),
    getIt<MigrationService>(),
  ));
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(
    getIt<Dio>(),
    getIt<SharedPreferences>(),
  ));
}