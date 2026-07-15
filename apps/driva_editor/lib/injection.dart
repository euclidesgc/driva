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

void setupInjection(AppConfig config, SharedPreferences prefs) {
  getIt.registerSingleton<AppConfig>(config);
  getIt.registerSingleton<ProjectScope>(
    ProjectScope(initialProjectId: config.defaultProjectId),
  );
  getIt.registerLazySingleton<Dio>(
    () => createDio(getIt<AppConfig>(), getIt<ProjectScope>()),
  );
  if (config.useFakeData) {
    getIt.registerLazySingleton<FakeContentsStore>(FakeContentsStore.new);
  }

  registerPreferencesModule(getIt, prefs);
  registerProjectsModule(getIt);
  registerContentsModule(getIt);
  registerEditorModule(getIt);
}
