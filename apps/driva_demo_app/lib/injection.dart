import 'package:dio/dio.dart';
import 'package:driva_demo_app/core/config/app_config.dart';
import 'package:driva_demo_app/core/network/network.dart';
import 'package:driva_demo_app/modules/published_module/published_module.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

void setupInjection(AppConfig config) {
  getIt
    ..registerSingleton<AppConfig>(config)
    ..registerLazySingleton<Dio>(() => createDio(getIt<AppConfig>()));

  registerPublishedModule(getIt);
}
