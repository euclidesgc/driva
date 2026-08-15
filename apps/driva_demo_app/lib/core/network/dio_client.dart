import 'package:dio/dio.dart';
import 'package:driva_demo_app/core/config/app_config.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

const String publishableKeyHeader = 'x-driva-key';

Dio createDio(AppConfig config) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {publishableKeyHeader: config.publishableKey},
    ),
  );
  if (!kReleaseMode) {
    dio.interceptors.add(LogInterceptor());
  }
  return dio;
}
