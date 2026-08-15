import 'package:dio/dio.dart';
import 'package:driva_demo_app/modules/published_module/data/repositories/repositories.dart';
import 'package:driva_demo_app/modules/published_module/domain/repositories/published_repository.dart';
import 'package:driva_demo_app/modules/published_module/domain/use_cases/use_cases.dart';
import 'package:get_it/get_it.dart';

void registerPublishedModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<PublishedRepository>(
      () => PublishedRepositoryImpl(getIt<Dio>()),
    )
    ..registerFactory(
      () => GetPublishedContentsUseCase(
        repository: getIt<PublishedRepository>(),
      ),
    )
    ..registerFactory(
      () => GetPublishedContentUseCase(
        repository: getIt<PublishedRepository>(),
      ),
    );
}
