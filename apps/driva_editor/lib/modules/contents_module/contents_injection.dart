import 'package:dio/dio.dart';
import 'package:driva_editor/core/config/app_config.dart';
import 'package:driva_editor/core/dev/fake_contents_store.dart';
import 'package:driva_editor/modules/contents_module/data/repositories/repositories.dart';
import 'package:driva_editor/modules/contents_module/domain/repositories/categories_repository.dart';
import 'package:driva_editor/modules/contents_module/domain/repositories/contents_repository.dart';
import 'package:driva_editor/modules/contents_module/domain/use_cases/use_cases.dart';
import 'package:get_it/get_it.dart';

void registerContentsModule(GetIt getIt) {
  getIt
    ..registerLazySingleton<ContentsRepository>(
      () => getIt<AppConfig>().useFakeData
          ? ContentsRepositoryFake(getIt<FakeContentsStore>())
          : ContentsRepositoryImpl(getIt<Dio>()),
    )
    ..registerLazySingleton<CategoriesRepository>(
      () => getIt<AppConfig>().useFakeData
          ? CategoriesRepositoryFake(getIt<FakeContentsStore>())
          : CategoriesRepositoryImpl(getIt<Dio>()),
    )
    ..registerFactory(
      () => GetContentsUseCase(repository: getIt<ContentsRepository>()),
    )
    ..registerFactory(
      () => CreateContentUseCase(repository: getIt<ContentsRepository>()),
    )
    ..registerFactory(
      () => DeleteContentUseCase(repository: getIt<ContentsRepository>()),
    )
    ..registerFactory(
      () => UpdateContentUseCase(repository: getIt<ContentsRepository>()),
    )
    ..registerFactory(
      () => GetCategoriesUseCase(repository: getIt<CategoriesRepository>()),
    )
    ..registerFactory(
      () => CreateCategoryUseCase(repository: getIt<CategoriesRepository>()),
    )
    ..registerFactory(
      () => UpdateCategoryUseCase(repository: getIt<CategoriesRepository>()),
    )
    ..registerFactory(
      () => DeleteCategoryUseCase(repository: getIt<CategoriesRepository>()),
    );
}
