import 'dart:async';

import 'package:driva_editor/modules/preferences_module/data/repositories/repositories.dart';
import 'package:driva_editor/modules/preferences_module/domain/repositories/preferences_repository.dart';
import 'package:driva_editor/modules/preferences_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/preferences_module/presentation/theme/cubit/theme_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerPreferencesModule(GetIt getIt, SharedPreferences prefs) {
  getIt
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<PreferencesRepository>(
      () => PreferencesRepositoryImpl(getIt<SharedPreferences>()),
    )
    ..registerFactory(
      () => GetThemeModeUseCase(repository: getIt<PreferencesRepository>()),
    )
    ..registerFactory(
      () => SaveThemeModeUseCase(repository: getIt<PreferencesRepository>()),
    )
    // Factory aqui daria um cubit novo por leitura: a troca de tema não
    // propagaria.
    ..registerLazySingleton<ThemeCubit>(() {
      final cubit = ThemeCubit(
        getThemeMode: getIt<GetThemeModeUseCase>(),
        saveThemeMode: getIt<SaveThemeModeUseCase>(),
      );
      unawaited(cubit.load());
      return cubit;
    });
}
