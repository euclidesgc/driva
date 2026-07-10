import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import '../../core/dev/fake_contents_store.dart';
import 'data/repositories/repositories.dart'; // barrel INTERNO (impls)
import 'domain/repositories/categories_repository.dart';
import 'domain/repositories/contents_repository.dart';
import 'domain/use_cases/use_cases.dart';

/// Registra as dependências do módulo de conteúdos (inclui categorias — ver
/// nota em `contents_module.dart`). Chamado pela raiz. Único arquivo que
/// importa as implementações e as casa com o contrato.
void registerContentsModule(GetIt getIt) {
  getIt.registerLazySingleton<ContentsRepository>(
    () => getIt<AppConfig>().useFakeData
        ? ContentsRepositoryFake(getIt<FakeContentsStore>())
        : ContentsRepositoryImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<CategoriesRepository>(
    () => getIt<AppConfig>().useFakeData
        ? CategoriesRepositoryFake()
        : CategoriesRepositoryImpl(getIt<Dio>()),
  );

  getIt.registerFactory(
    () => GetContentsUseCase(repository: getIt<ContentsRepository>()),
  );
  getIt.registerFactory(
    () => CreateContentUseCase(repository: getIt<ContentsRepository>()),
  );
  getIt.registerFactory(
    () => DeleteContentUseCase(repository: getIt<ContentsRepository>()),
  );
  getIt.registerFactory(
    () => UpdateContentUseCase(repository: getIt<ContentsRepository>()),
  );

  getIt.registerFactory(
    () => GetCategoriesUseCase(repository: getIt<CategoriesRepository>()),
  );
  getIt.registerFactory(
    () => CreateCategoryUseCase(repository: getIt<CategoriesRepository>()),
  );
  getIt.registerFactory(
    () => UpdateCategoryUseCase(repository: getIt<CategoriesRepository>()),
  );
  getIt.registerFactory(
    () => DeleteCategoryUseCase(repository: getIt<CategoriesRepository>()),
  );
}
