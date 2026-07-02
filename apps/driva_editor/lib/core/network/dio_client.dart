import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Creates the single shared [Dio] instance of the app.
///
/// Base URL comes from [AppConfig] (per flavor). Every repository receives
/// this same instance via injection — no module creates its own client.
Dio createDio(AppConfig config) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'x-project-id': config.defaultProjectId},
    ),
  );
  dio.interceptors.add(LogInterceptor(responseBody: false));
  return dio;
}
