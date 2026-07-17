import 'package:dio/dio.dart';
import 'package:driva_editor/core/config/app_config.dart';
import 'package:driva_editor/core/dev/fake_contents_store.dart';
import 'package:driva_editor/core/network/network.dart';
import 'package:driva_editor/modules/contents_module/contents_module.dart';
import 'package:driva_editor/modules/editor_module/editor_module.dart';
import 'package:driva_editor/modules/preferences_module/preferences_module.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt getIt = GetIt.instance;

void setupInjection(AppConfig config, SharedPreferences prefs) {
  getIt
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<ProjectScope>(
      ProjectScope(initialProjectId: config.defaultProjectId),
    )
    ..registerLazySingleton<Dio>(
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
