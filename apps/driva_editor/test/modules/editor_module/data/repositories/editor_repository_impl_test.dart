import 'package:dio/dio.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/repositories/editor_repository_impl.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late EditorRepositoryImpl repository;

  Map<String, dynamic> versionBody({int specVersion = kSpecVersion}) => {
    'version': 3,
    'spec': {
      'specVersion': specVersion,
      'kind': 'content',
      'id': 'ct_1',
      'name': 'Home',
      'slug': 'home',
    },
    'createdAt': '2026-08-16T10:30:00.000Z',
    'note': 'Ajuste no banner',
    'createdBy': 'user_1',
  };

  Response<T> ok<T>(T data) => Response<T>(
    data: data,
    requestOptions: RequestOptions(path: '/'),
  );

  DioException dioError(DioExceptionType type, {int? statusCode}) =>
      DioException(
        requestOptions: RequestOptions(path: '/'),
        type: type,
        response: statusCode == null
            ? null
            : Response(
                statusCode: statusCode,
                requestOptions: RequestOptions(path: '/'),
              ),
      );

  setUp(() {
    dio = _MockDio();
    repository = EditorRepositoryImpl(dio);
  });

  group('getVersion', () {
    test(
      'sucesso: uma única requisição de detalhe devolve LoadedContentVersion',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>('/v1/contents/ct_1/versions/3'),
        ).thenAnswer((_) async => ok(versionBody()));

        final result = await repository.getVersion('ct_1', 3);

        final loaded = result.getRight().toNullable();
        expect(loaded, isA<LoadedContentVersion>());
        expect(loaded!.version, 3);
        expect(loaded.spec.id, 'ct_1');
        expect(loaded.note, 'Ajuste no banner');
        verify(
          () => dio.get<Map<String, dynamic>>('/v1/contents/ct_1/versions/3'),
        ).called(1);
      },
    );

    test(
      '404 do servidor vira Left(NotFoundFailure), sem lançar exceção',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>('/v1/contents/ct_1/versions/9'),
        ).thenThrow(dioError(DioExceptionType.badResponse, statusCode: 404));

        final result = await repository.getVersion('ct_1', 9);

        expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
      },
    );

    test(
      'falha de conexão vira Left(NetworkFailure), sem lançar exceção',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>('/v1/contents/ct_1/versions/3'),
        ).thenThrow(dioError(DioExceptionType.connectionError));

        final result = await repository.getVersion('ct_1', 3);

        expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      },
    );

    test(
      'JSON inválido (specVersion incompatível) vira Left(ValidationFailure)',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>('/v1/contents/ct_1/versions/3'),
        ).thenAnswer(
          (_) async => ok(versionBody(specVersion: kSpecVersion + 1)),
        );

        final result = await repository.getVersion('ct_1', 3);

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      },
    );

    test('resposta sem "spec" vira Left(ValidationFailure)', () async {
      final body = versionBody()..remove('spec');
      when(
        () => dio.get<Map<String, dynamic>>('/v1/contents/ct_1/versions/3'),
      ).thenAnswer((_) async => ok(body));

      final result = await repository.getVersion('ct_1', 3);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });
}
