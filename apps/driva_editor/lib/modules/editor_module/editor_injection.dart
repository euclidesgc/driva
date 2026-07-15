import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import '../../core/dev/fake_contents_store.dart';
import 'data/repositories/repositories.dart';
import 'domain/repositories/editor_repository.dart';
import 'domain/use_cases/use_cases.dart';

void registerEditorModule(GetIt getIt) {
  getIt.registerLazySingleton<EditorRepository>(
    () => getIt<AppConfig>().useFakeData
        ? EditorRepositoryFake(getIt<FakeContentsStore>())
        : EditorRepositoryImpl(getIt<Dio>()),
  );

  getIt.registerFactory(
    () => LoadContentUseCase(repository: getIt<EditorRepository>()),
  );
  getIt.registerFactory(
    () => SaveDraftUseCase(repository: getIt<EditorRepository>()),
  );
}
