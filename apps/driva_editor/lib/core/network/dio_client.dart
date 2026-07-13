import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

import '../config/app_config.dart';
import 'project_scope.dart';

/// Creates the single shared [Dio] instance of the app.
///
/// Base URL comes from [AppConfig] (per flavor). Every repository receives
/// this same instance via injection — no module creates its own client.
///
/// `x-project-id` is stamped per-request by an interceptor reading
/// [scope], so it follows whichever project the user has open instead of
/// being fixed at client-creation time.
Dio createDio(AppConfig config, ProjectScope scope) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['x-project-id'] = scope.projectId;
        handler.next(options);
      },
    ),
  );
  if (!kReleaseMode) {
    dio.interceptors.add(LogInterceptor(responseBody: false));
  }
  return dio;
}
