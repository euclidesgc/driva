import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/repositories.dart';
import 'domain/repositories/preferences_repository.dart';
import 'domain/use_cases/use_cases.dart';
import 'presentation/theme/cubit/theme_cubit.dart';

void registerPreferencesModule(GetIt getIt, SharedPreferences prefs) {
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton<PreferencesRepository>(
    () => PreferencesRepositoryImpl(getIt<SharedPreferences>()),
  );

  getIt.registerFactory(
    () => GetThemeModeUseCase(repository: getIt<PreferencesRepository>()),
  );
  getIt.registerFactory(
    () => SaveThemeModeUseCase(repository: getIt<PreferencesRepository>()),
  );

  // Factory aqui daria um cubit novo por leitura: a troca de tema não propagaria.
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(
      getThemeMode: getIt<GetThemeModeUseCase>(),
      saveThemeMode: getIt<SaveThemeModeUseCase>(),
    )..load(),
  );
}
