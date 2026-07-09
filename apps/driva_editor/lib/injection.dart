import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/dev/fake_contents_store.dart';
import 'core/network/network.dart';
import 'modules/contents_module/contents_module.dart';
import 'modules/editor_module/editor_module.dart';
import 'modules/preferences_module/preferences_module.dart';
import 'modules/projects_module/projects_module.dart';

final GetIt getIt = GetIt.instance;

/// Root of the service locator.
///
/// Order matters: shared infra first (config, the single Dio of the app),
/// then each module's public registration function.
///
/// The root only knows the modules' public barrels — implementations stay
/// locked inside each module.
void setupInjection(AppConfig config, SharedPreferences prefs) {
  // --- Shared infra ---
  getIt.registerSingleton<AppConfig>(config);
  getIt.registerLazySingleton<Dio>(() => createDio(getIt<AppConfig>()));
  if (config.useFakeData) {
    // Store em memória compartilhado pelos fakes dos módulos (dev/E2E).
    getIt.registerLazySingleton<FakeContentsStore>(FakeContentsStore.new);
  }

  // --- Module registrations ---
  registerPreferencesModule(getIt, prefs);
  registerProjectsModule(getIt);
  registerContentsModule(getIt);
  registerEditorModule(getIt);
}
