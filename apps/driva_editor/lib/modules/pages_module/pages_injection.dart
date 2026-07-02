import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import '../../core/dev/fake_pages_store.dart';
import 'data/repositories/repositories.dart'; // barrel INTERNO (impls)
import 'domain/repositories/pages_repository.dart';
import 'domain/use_cases/use_cases.dart';

/// Registra as dependências do módulo de páginas. Chamado pela raiz.
/// Único arquivo que importa as implementações e as casa com o contrato.
void registerPagesModule(GetIt getIt) {
  getIt.registerLazySingleton<PagesRepository>(
    () => getIt<AppConfig>().useFakeData
        ? PagesRepositoryFake(getIt<FakePagesStore>())
        : PagesRepositoryImpl(getIt<Dio>()),
  );

  getIt.registerFactory(
    () => GetPagesUseCase(repository: getIt<PagesRepository>()),
  );
  getIt.registerFactory(
    () => CreatePageUseCase(repository: getIt<PagesRepository>()),
  );
  getIt.registerFactory(
    () => DeletePageUseCase(repository: getIt<PagesRepository>()),
  );
}
