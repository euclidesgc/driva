import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/repositories.dart'; // barrel INTERNO (impls)
import 'domain/repositories/preferences_repository.dart';
import 'domain/use_cases/use_cases.dart';
import 'presentation/theme/cubit/theme_cubit.dart';

/// Registra as dependências do módulo de preferências. Chamado pela raiz.
/// Único arquivo que importa a implementação e a casa com o contrato.
///
/// A instância de [SharedPreferences] é resolvida uma única vez, de forma
/// assíncrona, antes do `runApp` (veja `bootstrap.dart`).
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

  // O ThemeCubit vive acima do MaterialApp: singleton (uma instância para toda
  // a app), criado já carregando a preferência persistida.
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(
      getThemeMode: getIt<GetThemeModeUseCase>(),
      saveThemeMode: getIt<SaveThemeModeUseCase>(),
    )..load(),
  );
}
