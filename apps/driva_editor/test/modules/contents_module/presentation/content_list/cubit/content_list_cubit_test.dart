import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/contents_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/contents_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetContentsUseCase extends Mock implements GetContentsUseCase {}

class MockCreateContentUseCase extends Mock implements CreateContentUseCase {}

class MockDeleteContentUseCase extends Mock implements DeleteContentUseCase {}

void main() {
  late MockGetContentsUseCase getContents;
  late MockCreateContentUseCase createContent;
  late MockDeleteContentUseCase deleteContent;

  final content = ContentSummary(
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    categoryId: 'cat_1',
    description: 'Vitrine',
    updatedAt: DateTime(2026, 7, 1),
  );

  final other = ContentSummary(
    id: 'ct_2',
    name: 'Sobre',
    slug: 'sobre',
    categoryId: 'cat_1',
    description: null,
    updatedAt: DateTime(2026, 7, 2),
  );

  setUp(() {
    getContents = MockGetContentsUseCase();
    createContent = MockCreateContentUseCase();
    deleteContent = MockDeleteContentUseCase();
  });

  ContentListCubit build() => ContentListCubit(
    getContents: getContents,
    createContent: createContent,
    deleteContent: deleteContent,
  );

  group('load', () {
    blocTest<ContentListCubit, ContentListState>(
      'emite Loading → Loaded quando há conteúdos',
      build: build,
      setUp: () => when(
        () => getContents(),
      ).thenAnswer((_) async => Right(ContentsPage(items: [content]))),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ContentListLoading(),
        ContentListLoaded(contents: [content]),
      ],
    );

    blocTest<ContentListCubit, ContentListState>(
      'emite Loading → Empty quando não há conteúdos',
      build: build,
      setUp: () => when(
        () => getContents(),
      ).thenAnswer((_) async => const Right(ContentsPage(items: []))),
      act: (cubit) => cubit.load(),
      expect: () => [const ContentListLoading(), const ContentListEmpty()],
    );

    blocTest<ContentListCubit, ContentListState>(
      'emite Loading → Error com a Failure tipada',
      build: build,
      setUp: () => when(
        () => getContents(),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ContentListLoading(),
        const ContentListError(failure: NetworkFailure()),
      ],
    );
  });

  group('changeSort', () {
    blocTest<ContentListCubit, ContentListState>(
      'muda campo e direção e recarrega passando sort/order ao use case',
      build: build,
      setUp: () => when(
        () => getContents(sort: ContentSort.name, order: ContentSortOrder.asc),
      ).thenAnswer((_) async => Right(ContentsPage(items: [content]))),
      act: (cubit) =>
          cubit.changeSort(sort: ContentSort.name, order: ContentSortOrder.asc),
      expect: () => [
        const ContentListLoading(),
        ContentListLoaded(contents: [content]),
      ],
      verify: (_) {
        verify(
          () =>
              getContents(sort: ContentSort.name, order: ContentSortOrder.asc),
        ).called(1);
      },
    );

    test('getters refletem a ordenação corrente após changeSort', () async {
      when(
        () => getContents(sort: ContentSort.createdAt),
      ).thenAnswer((_) async => const Right(ContentsPage(items: [])));
      final cubit = build();
      expect(cubit.currentSort, ContentSort.updatedAt);
      expect(cubit.currentOrder, ContentSortOrder.desc);
      await cubit.changeSort(sort: ContentSort.createdAt);
      expect(cubit.currentSort, ContentSort.createdAt);
      expect(cubit.currentOrder, ContentSortOrder.desc);
      await cubit.close();
    });
  });

  group('load (paginação)', () {
    blocTest<ContentListCubit, ContentListState>(
      'guarda o nextCursor da primeira página',
      build: build,
      setUp: () => when(() => getContents()).thenAnswer(
        (_) async => Right(ContentsPage(items: [content], nextCursor: 'c1')),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ContentListLoading(),
        ContentListLoaded(contents: [content], nextCursor: 'c1'),
      ],
    );
  });

  group('loadMore', () {
    blocTest<ContentListCubit, ContentListState>(
      'anexa a próxima página e atualiza o cursor',
      build: build,
      seed: () => ContentListLoaded(contents: [content], nextCursor: 'c1'),
      setUp: () => when(() => getContents(cursor: 'c1')).thenAnswer(
        (_) async => Right(ContentsPage(items: [other], nextCursor: 'c2')),
      ),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        ContentListLoaded(
          contents: [content],
          nextCursor: 'c1',
          isLoadingMore: true,
        ),
        ContentListLoaded(contents: [content, other], nextCursor: 'c2'),
      ],
      verify: (_) => verify(() => getContents(cursor: 'c1')).called(1),
    );

    blocTest<ContentListCubit, ContentListState>(
      'nextCursor nulo na resposta encerra a paginação (hasMore = false)',
      build: build,
      seed: () => ContentListLoaded(contents: [content], nextCursor: 'c1'),
      setUp: () => when(
        () => getContents(cursor: 'c1'),
      ).thenAnswer((_) async => Right(ContentsPage(items: [other]))),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        ContentListLoaded(
          contents: [content],
          nextCursor: 'c1',
          isLoadingMore: true,
        ),
        ContentListLoaded(contents: [content, other]),
      ],
    );

    blocTest<ContentListCubit, ContentListState>(
      'no-op quando não há próxima página (nextCursor == null)',
      build: build,
      seed: () => ContentListLoaded(contents: [content]),
      act: (cubit) => cubit.loadMore(),
      expect: () => <ContentListState>[],
      verify: (_) =>
          verifyNever(() => getContents(cursor: any(named: 'cursor'))),
    );

    blocTest<ContentListCubit, ContentListState>(
      'falha mantém a lista e o cursor, só desliga o isLoadingMore',
      build: build,
      seed: () => ContentListLoaded(contents: [content], nextCursor: 'c1'),
      setUp: () => when(
        () => getContents(cursor: 'c1'),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        ContentListLoaded(
          contents: [content],
          nextCursor: 'c1',
          isLoadingMore: true,
        ),
        ContentListLoaded(contents: [content], nextCursor: 'c1'),
      ],
    );
  });

  group('create', () {
    blocTest<ContentListCubit, ContentListState>(
      'sucesso: não emite estado nem recarrega — devolve o conteúdo criado',
      build: build,
      setUp: () => when(
        () => createContent(name: 'Home', slug: 'home', description: null),
      ).thenAnswer((_) async => Right(content)),
      act: (cubit) async {
        final result = await cubit.create(name: 'Home', slug: 'home');
        expect(result, Right<Failure, ContentSummary>(content));
      },
      expect: () => <ContentListState>[],
      verify: (_) => verifyNever(() => getContents()),
    );

    blocTest<ContentListCubit, ContentListState>(
      'conflito: não recarrega e devolve ConflictFailure com sugestão',
      build: build,
      setUp: () =>
          when(
            () => createContent(name: 'Home', slug: 'home', description: null),
          ).thenAnswer(
            (_) async => const Left(ConflictFailure(suggestedSlug: 'home-2')),
          ),
      act: (cubit) => cubit.create(name: 'Home', slug: 'home'),
      expect: () => <ContentListState>[],
      verify: (_) => verifyNever(() => getContents()),
    );
  });

  group('delete', () {
    blocTest<ContentListCubit, ContentListState>(
      'sucesso otimista: remove o card na hora sem Loading nem reload',
      build: build,
      seed: () => ContentListLoaded(contents: [content, other]),
      setUp: () => when(
        () => deleteContent('ct_1'),
      ).thenAnswer((_) async => const Right(unit)),
      act: (cubit) async {
        final result = await cubit.delete('ct_1');
        expect(result, const Right<Failure, Unit>(unit));
      },
      expect: () => [
        ContentListLoaded(contents: [other]),
      ],
      verify: (_) => verifyNever(() => getContents()),
    );

    blocTest<ContentListCubit, ContentListState>(
      'sucesso otimista: excluir o último card vira Empty',
      build: build,
      seed: () => ContentListLoaded(contents: [content]),
      setUp: () => when(
        () => deleteContent('ct_1'),
      ).thenAnswer((_) async => const Right(unit)),
      act: (cubit) => cubit.delete('ct_1'),
      expect: () => [const ContentListEmpty()],
      verify: (_) => verifyNever(() => getContents()),
    );

    blocTest<ContentListCubit, ContentListState>(
      'falha: remove otimista, reconcilia via load() e devolve Left',
      build: build,
      seed: () => ContentListLoaded(contents: [content, other]),
      setUp: () {
        when(
          () => deleteContent('ct_1'),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        when(
          () => getContents(),
        ).thenAnswer((_) async => Right(ContentsPage(items: [content, other])));
      },
      act: (cubit) async {
        final result = await cubit.delete('ct_1');
        expect(result, const Left<Failure, Unit>(NetworkFailure()));
      },
      expect: () => [
        ContentListLoaded(contents: [other]),
        const ContentListLoading(),
        ContentListLoaded(contents: [content, other]),
      ],
      verify: (_) => verify(() => getContents()).called(1),
    );
  });
}
