import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:driva_editor/core/network/network.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._steps);

  final List<Object> _steps;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = callCount;
    callCount++;
    final step = index < _steps.length ? _steps[index] : _steps.last;
    if (step is DioExceptionType) {
      throw DioException(requestOptions: options, type: step);
    }
    final statusCode = step as int;
    return ResponseBody.fromString(
      jsonEncode(const {'ok': true}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
  dio.interceptors.add(RetryInterceptor(dio, retryDelays: const []));
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  group('RetryInterceptor', () {
    test(
      'falha transitória seguida de sucesso resulta em sucesso para o '
      'chamador, sem exceção nem Failure exposta',
      () async {
        final adapter = _ScriptedAdapter([
          DioExceptionType.connectionError,
          200,
        ]);
        final dio = _dioWith(adapter);

        final response = await dio.get<Map<String, dynamic>>('/v1/projects');

        expect(response.statusCode, 200);
        expect(adapter.callCount, 2);
      },
    );

    test(
      'requisição não-idempotente (POST) não é repetida após falha',
      () async {
        final adapter = _ScriptedAdapter([
          DioExceptionType.connectionError,
          200,
        ]);
        final dio = _dioWith(adapter);

        await expectLater(
          dio.post<Map<String, dynamic>>('/v1/projects'),
          throwsA(isA<DioException>()),
        );
        expect(adapter.callCount, 1);
      },
    );

    test('erro 4xx não dispara retry', () async {
      final adapter = _ScriptedAdapter([400, 200]);
      final dio = _dioWith(adapter);

      await expectLater(
        dio.get<Map<String, dynamic>>('/v1/projects'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, 1);
    });

    test('502 transitório é reprocessado até o limite de tentativas', () async {
      final adapter = _ScriptedAdapter([502, 502, 200]);
      final dio = _dioWith(adapter);

      final response = await dio.get<Map<String, dynamic>>('/v1/projects');

      expect(response.statusCode, 200);
      expect(adapter.callCount, 3);
    });

    test('falha persistente para de tentar após maxRetries', () async {
      final adapter = _ScriptedAdapter([
        DioExceptionType.connectionError,
        DioExceptionType.connectionError,
        DioExceptionType.connectionError,
      ]);
      final dio = _dioWith(adapter);

      await expectLater(
        dio.get<Map<String, dynamic>>('/v1/projects'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, 3);
    });
  });
}
