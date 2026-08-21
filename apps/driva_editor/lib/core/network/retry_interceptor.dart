import 'package:dio/dio.dart';

/// Retries a request after a transient network failure, capped at
/// [maxRetries] attempts with a short backoff between them.
///
/// Only GET/HEAD/OPTIONS are retried — a POST/PUT/PATCH/DELETE might not be
/// idempotent on the backend (e.g. publishing twice), so repeating it
/// automatically after a failure could do more damage than the original
/// error. A 4xx is the server rejecting the request as-is, so retrying
/// changes nothing; only connection-level failures and 502/503/504 are
/// worth a second try.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 2,
    this.retryDelays = const [
      Duration(milliseconds: 300),
      Duration(milliseconds: 800),
    ],
  });

  final Dio _dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  static const _retryCountKey = 'retry_count';

  @override
  // `Interceptor.onError` is declared `void` — the handler resolves the
  // request asynchronously via its own callback, not via this method's
  // return value, so `Future<void>` isn't a valid override here.
  // ignore: avoid_void_async
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;
    if (attempt >= maxRetries || !_isRetryable(err)) {
      handler.next(err);
      return;
    }

    final delay = retryDelays.isEmpty
        ? Duration.zero
        : retryDelays[attempt.clamp(0, retryDelays.length - 1)];
    await Future<void>.delayed(delay);

    final retryOptions = err.requestOptions
      ..extra[_retryCountKey] = attempt + 1;

    try {
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isRetryable(DioException err) {
    if (!_isIdempotentMethod(err.requestOptions.method)) return false;
    return switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.badResponse => _isRetryableStatus(
        err.response?.statusCode,
      ),
      _ => false,
    };
  }

  bool _isIdempotentMethod(String method) => switch (method.toUpperCase()) {
    'GET' || 'HEAD' || 'OPTIONS' => true,
    _ => false,
  };

  bool _isRetryableStatus(int? status) =>
      status == 502 || status == 503 || status == 504;
}
