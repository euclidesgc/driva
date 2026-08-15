import 'package:bloc_test/bloc_test.dart';
import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:driva_demo_app/modules/published_module/domain/repositories/published_repository.dart';
import 'package:driva_demo_app/modules/published_module/domain/use_cases/use_cases.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/cubit/content_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockPublishedRepository extends Mock implements PublishedRepository {}

final _content = PublishedContent(
  spec: const ContentSpec(
    specVersion: 1,
    id: 'c1',
    name: 'Vitrine',
    slug: 'vitrine',
  ),
  updatedAt: DateTime.utc(2026, 8, 14),
  etag: '"c1-1"',
);

void main() {
  late MockPublishedRepository repository;
  late ContentCubit cubit;

  ContentCubit build() => ContentCubit(
    getPublishedContent: GetPublishedContentUseCase(repository: repository),
    slug: 'vitrine',
  );

  setUp(() {
    repository = MockPublishedRepository();
    cubit = build();
  });

  tearDown(() => cubit.close());

  blocTest<ContentCubit, ContentState>(
    'load busca o conteúdo do slug e emite Loaded',
    setUp: () => when(
      () => repository.getPublishedContent('vitrine'),
    ).thenAnswer((_) async => Right(_content)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const ContentLoading(),
      ContentLoaded(content: _content),
    ],
  );

  blocTest<ContentCubit, ContentState>(
    'slug inexistente vira ContentError com a falha do repositório',
    setUp: () => when(
      () => repository.getPublishedContent('vitrine'),
    ).thenAnswer((_) async => const Left(NotFoundFailure())),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const ContentLoading(),
      const ContentError(failure: NotFoundFailure()),
    ],
  );
}
