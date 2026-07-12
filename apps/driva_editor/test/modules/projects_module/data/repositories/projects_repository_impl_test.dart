import 'package:dio/dio.dart';
import 'package:driva_editor/modules/projects_module/data/repositories/projects_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

// `updatedAt` da fixture — a `imageUrl` resolvida ganha `?v=<epoch>` como
// cache-buster (a URL de serving é estável, então versionamos pelo updatedAt).
const _updatedAt = '2026-07-11T00:00:00.000Z';
final _version = DateTime.parse(_updatedAt).millisecondsSinceEpoch;

void main() {
  late _MockDio dio;
  late ProjectsRepositoryImpl repository;

  Map<String, dynamic> projectJson({String? imageUrl}) => {
    'id': 'p1',
    'title': 'Projeto',
    'imageUrl': imageUrl,
    'createdAt': '2026-07-11T00:00:00.000Z',
    'updatedAt': _updatedAt,
    'contentCount': 0,
    'categoryCount': 1,
    'archivedAt': null,
  };

  Response<T> ok<T>(T data) => Response<T>(
    data: data,
    requestOptions: RequestOptions(path: '/'),
  );

  setUp(() {
    dio = _MockDio();
    when(
      () => dio.options,
    ).thenReturn(BaseOptions(baseUrl: 'https://api-hml.driva.duckdns.org'));
    repository = ProjectsRepositoryImpl(dio);
  });

  group('_resolveImageUrl (bug da imagem que "não persistia")', () {
    test(
      'getProjects: imageUrl relativa vira absoluta (base da API)',
      () async {
        when(
          () => dio.get<List<dynamic>>(
            '/v1/projects',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => ok<List<dynamic>>([
            projectJson(imageUrl: '/v1/projects/p1/image'),
          ]),
        );

        final result = await repository.getProjects();

        final projects = result.getRight().toNullable()!;
        expect(
          projects.single.imageUrl,
          'https://api-hml.driva.duckdns.org/v1/projects/p1/image?v=$_version',
        );
      },
    );

    test('getProject: imageUrl relativa vira absoluta', () async {
      when(() => dio.get<Map<String, dynamic>>('/v1/projects/p1')).thenAnswer(
        (_) async => ok<Map<String, dynamic>>(
          projectJson(imageUrl: '/v1/projects/p1/image'),
        ),
      );

      final result = await repository.getProject('p1');

      expect(
        result.getRight().toNullable()!.imageUrl,
        'https://api-hml.driva.duckdns.org/v1/projects/p1/image?v=$_version',
      );
    });

    test('imageUrl nula permanece nula (projeto sem imagem)', () async {
      when(() => dio.get<Map<String, dynamic>>('/v1/projects/p1')).thenAnswer(
        (_) async => ok<Map<String, dynamic>>(projectJson(imageUrl: null)),
      );

      final result = await repository.getProject('p1');

      expect(result.getRight().toNullable()!.imageUrl, isNull);
    });

    test('imageUrl já absoluta passa intacta (idempotente)', () async {
      const absolute = 'https://cdn.example.com/img.png';
      when(() => dio.get<Map<String, dynamic>>('/v1/projects/p1')).thenAnswer(
        (_) async => ok<Map<String, dynamic>>(projectJson(imageUrl: absolute)),
      );

      final result = await repository.getProject('p1');

      expect(result.getRight().toNullable()!.imageUrl, absolute);
    });
  });
}
