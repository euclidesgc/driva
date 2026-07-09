import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../core/config/app_config.dart';
import 'data/repositories/repositories.dart'; // barrel INTERNO (impls)
import 'domain/repositories/projects_repository.dart';
import 'domain/use_cases/use_cases.dart';

/// Registra as dependências do módulo de projetos. Chamado pela raiz.
/// Único arquivo que importa as implementações e as casa com o contrato.
void registerProjectsModule(GetIt getIt) {
  getIt.registerLazySingleton<ProjectsRepository>(
    () => getIt<AppConfig>().useFakeData
        ? ProjectsRepositoryFake()
        : ProjectsRepositoryImpl(getIt<Dio>()),
  );

  getIt.registerFactory(
    () => GetProjectsUseCase(repository: getIt<ProjectsRepository>()),
  );
  getIt.registerFactory(
    () => GetProjectUseCase(repository: getIt<ProjectsRepository>()),
  );
  getIt.registerFactory(
    () => CreateProjectUseCase(repository: getIt<ProjectsRepository>()),
  );
  getIt.registerFactory(
    () => UpdateProjectUseCase(repository: getIt<ProjectsRepository>()),
  );
  getIt.registerFactory(
    () => DeleteProjectUseCase(repository: getIt<ProjectsRepository>()),
  );
}
