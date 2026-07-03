import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import '../../core/dev/fake_contents_store.dart';
import 'data/repositories/repositories.dart'; // barrel INTERNO (impls)
import 'domain/repositories/contents_repository.dart';
import 'domain/use_cases/use_cases.dart';

/// Registra as dependências do módulo de conteúdos. Chamado pela raiz.
/// Único arquivo que importa as implementações e as casa com o contrato.
void registerContentsModule(GetIt getIt) {
  getIt.registerLazySingleton<ContentsRepository>(
    () => getIt<AppConfig>().useFakeData
        ? ContentsRepositoryFake(getIt<FakeContentsStore>())
        : ContentsRepositoryImpl(getIt<Dio>()),
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
}
