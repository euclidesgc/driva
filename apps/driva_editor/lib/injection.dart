import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'core/config/app_config.dart';
import 'core/dev/fake_pages_store.dart';
import 'core/network/network.dart';
import 'modules/pages_module/pages_module.dart';

final GetIt getIt = GetIt.instance;

/// Root of the service locator.
///
/// Order matters: shared infra first (config, the single Dio of the app),
/// then each module's public registration function.
///
/// The root only knows the modules' public barrels — implementations stay
/// locked inside each module.
void setupInjection(AppConfig config) {
  // --- Shared infra ---
  getIt.registerSingleton<AppConfig>(config);
  getIt.registerLazySingleton<Dio>(() => createDio(getIt<AppConfig>()));
  if (config.useFakeData) {
    // Store em memória compartilhado pelos fakes dos módulos (dev/E2E).
    getIt.registerLazySingleton<FakePagesStore>(FakePagesStore.new);
  }

  // --- Module registrations ---
  registerPagesModule(getIt);
  // TODO(fase-4): registerEditorModule(getIt);
}
