import 'package:get_it/get_it.dart';

import '../features/game_field/cubit/game_field_cubit.dart';
import '../features/main_menu/service/game_storage_service.dart';
import '../features/stats/cubit/stats_cubit.dart';

final getIt = GetIt.instance;

/// Настройка Dependency Injection
///
/// Регистрация всех сервисов и кубитов.
/// Вызывается в main.dart при старте приложения.
void setupDI() {
  // Services
  getIt.registerLazySingleton<GameStorageService>(() => GameStorageService());

  // Cubits
  getIt.registerFactory<GameFieldCubit>(
    () => GameFieldCubit(storage: getIt<GameStorageService>()),
  );
  getIt.registerFactory<StatsCubit>(() => StatsCubit());

  // TODO: Этап 5 — Зарегистрировать AdService
  // getIt.registerLazySingleton<AdService>(() => AdService());
}
