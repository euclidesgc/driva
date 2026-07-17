import 'package:dio/dio.dart';
import 'package:driva_editor/core/config/app_config.dart';
import 'package:driva_editor/modules/projects_module/data/repositories/repositories.dart';
import 'package:driva_editor/modules/projects_module/domain/repositories/projects_repository.dart';
import 'package:driva_editor/modules/projects_module/domain/use_cases/use_cases.dart';
import 'package:get_it/get_it.dart';

void registerProjectsModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<ProjectsRepository>(
      () => getIt<AppConfig>().useFakeData
          ? ProjectsRepositoryFake()
          : ProjectsRepositoryImpl(getIt<Dio>()),
    )
    ..registerFactory(
      () => GetProjectsUseCase(repository: getIt<ProjectsRepository>()),
    )
    ..registerFactory(
      () => GetProjectUseCase(repository: getIt<ProjectsRepository>()),
    )
    ..registerFactory(
      () => CreateProjectUseCase(repository: getIt<ProjectsRepository>()),
    )
    ..registerFactory(
      () => UpdateProjectUseCase(repository: getIt<ProjectsRepository>()),
    )
    ..registerFactory(
      () => DeleteProjectUseCase(repository: getIt<ProjectsRepository>()),
    )
    ..registerFactory(
      () => ArchiveProjectUseCase(repository: getIt<ProjectsRepository>()),
    )
    ..registerFactory(
      () => UnarchiveProjectUseCase(repository: getIt<ProjectsRepository>()),
    );
}
