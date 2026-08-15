import 'package:bloc_test/bloc_test.dart';
import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:driva_demo_app/modules/published_module/domain/repositories/published_repository.dart';
import 'package:driva_demo_app/modules/published_module/domain/use_cases/use_cases.dart';
import 'package:driva_demo_app/modules/published_module/presentation/catalog/cubit/catalog_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPublishedRepository extends Mock implements PublishedRepository {}

final _items = [
  PublishedSummary(
    id: 'c1',
    name: 'Vitrine',
    slug: 'vitrine',
    updatedAt: DateTime.utc(2026, 8, 14),
  ),
];

void main() {
  late MockPublishedRepository repository;

  CatalogCubit build() => CatalogCubit(
    getPublishedContents: GetPublishedContentsUseCase(repository: repository),
  );

  setUp(() => repository = MockPublishedRepository());

  blocTest<CatalogCubit, CatalogState>(
    'load emite Loaded com o que a API publicou',
    setUp: () => when(
      repository.getPublishedContents,
    ).thenAnswer((_) async => Right(_items)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const CatalogLoading(), CatalogLoaded(items: _items)],
  );

  blocTest<CatalogCubit, CatalogState>(
    'projeto sem conteúdo emite Empty, não Loaded vazio',
    setUp: () => when(
      repository.getPublishedContents,
    ).thenAnswer((_) async => const Right([])),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const CatalogLoading(), const CatalogEmpty()],
  );

  blocTest<CatalogCubit, CatalogState>(
    'falha de rede emite Error',
    setUp: () => when(
      repository.getPublishedContents,
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const CatalogLoading(),
      const CatalogError(failure: NetworkFailure()),
    ],
  );
}
