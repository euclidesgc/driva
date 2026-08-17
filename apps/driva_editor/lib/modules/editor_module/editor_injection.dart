import 'package:dio/dio.dart';
import 'package:driva_editor/core/config/app_config.dart';
import 'package:driva_editor/core/dev/fake_contents_store.dart';
import 'package:driva_editor/modules/editor_module/data/repositories/repositories.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_layout_repository.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerEditorModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<EditorRepository>(
      () => getIt<AppConfig>().useFakeData
          ? EditorRepositoryFake(getIt<FakeContentsStore>())
          : EditorRepositoryImpl(getIt<Dio>()),
    )
    ..registerFactory(
      () => LoadContentUseCase(repository: getIt<EditorRepository>()),
    )
    ..registerFactory(
      () => SaveDraftUseCase(repository: getIt<EditorRepository>()),
    )
    ..registerFactory(
      () => PublishContentUseCase(repository: getIt<EditorRepository>()),
    )
    ..registerFactory(
      () => UnpublishContentUseCase(repository: getIt<EditorRepository>()),
    )
    ..registerFactory(
      () => GetContentVersionsUseCase(repository: getIt<EditorRepository>()),
    )
    ..registerFactory(
      () => RestoreContentVersionUseCase(repository: getIt<EditorRepository>()),
    )
    ..registerLazySingleton<EditorLayoutRepository>(
      () => EditorLayoutRepositoryImpl(getIt<SharedPreferences>()),
    )
    ..registerFactory(
      () => GetEditorLayoutUseCase(
        repository: getIt<EditorLayoutRepository>(),
      ),
    )
    ..registerFactory(
      () => SaveEditorLayoutUseCase(
        repository: getIt<EditorLayoutRepository>(),
      ),
    );
}
