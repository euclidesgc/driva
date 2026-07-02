import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/pages_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/pages_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/pages_module/presentation/page_list/cubit/page_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetPagesUseCase extends Mock implements GetPagesUseCase {}

class MockCreatePageUseCase extends Mock implements CreatePageUseCase {}

class MockDeletePageUseCase extends Mock implements DeletePageUseCase {}

void main() {
  late MockGetPagesUseCase getPages;
  late MockCreatePageUseCase createPage;
  late MockDeletePageUseCase deletePage;

  final page = PageSummary(
    id: 'pg_1',
    name: 'Home',
    screenTarget: 'home',
    updatedAt: DateTime(2026, 7, 1),
  );

  setUp(() {
    getPages = MockGetPagesUseCase();
    createPage = MockCreatePageUseCase();
    deletePage = MockDeletePageUseCase();
  });

  PageListCubit build() => PageListCubit(
        getPages: getPages,
        createPage: createPage,
        deletePage: deletePage,
      );

  group('load', () {
    blocTest<PageListCubit, PageListState>(
      'emite Loading → Loaded quando há páginas',
      build: build,
      setUp: () => when(() => getPages())
          .thenAnswer((_) async => Right([page])),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PageListLoading(),
        PageListLoaded(pages: [page]),
      ],
    );

    blocTest<PageListCubit, PageListState>(
      'emite Loading → Empty quando não há páginas',
      build: build,
      setUp: () => when(() => getPages())
          .thenAnswer((_) async => const Right([])),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PageListLoading(),
        const PageListEmpty(),
      ],
    );

    blocTest<PageListCubit, PageListState>(
      'emite Loading → Error com a Failure tipada',
      build: build,
      setUp: () => when(() => getPages())
          .thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PageListLoading(),
        const PageListError(failure: NetworkFailure()),
      ],
    );
  });

  group('create', () {
    blocTest<PageListCubit, PageListState>(
      'sucesso: recarrega a lista e devolve a página criada',
      build: build,
      setUp: () {
        when(() => createPage(name: 'Home', screenTarget: 'home'))
            .thenAnswer((_) async => Right(page));
        when(() => getPages()).thenAnswer((_) async => Right([page]));
      },
      act: (cubit) => cubit.create(name: 'Home', screenTarget: 'home'),
      expect: () => [
        const PageListLoading(),
        PageListLoaded(pages: [page]),
      ],
      verify: (_) => verify(() => getPages()).called(1),
    );

    blocTest<PageListCubit, PageListState>(
      'falha: não recarrega e não muda o estado',
      build: build,
      setUp: () =>
          when(() => createPage(name: 'Home', screenTarget: 'home'))
              .thenAnswer((_) async => const Left(ValidationFailure('x'))),
      act: (cubit) => cubit.create(name: 'Home', screenTarget: 'home'),
      expect: () => <PageListState>[],
      verify: (_) => verifyNever(() => getPages()),
    );
  });

  group('delete', () {
    blocTest<PageListCubit, PageListState>(
      'recarrega após excluir',
      build: build,
      setUp: () {
        when(() => deletePage('pg_1'))
            .thenAnswer((_) async => const Right(unit));
        when(() => getPages()).thenAnswer((_) async => const Right([]));
      },
      act: (cubit) => cubit.delete('pg_1'),
      expect: () => [
        const PageListLoading(),
        const PageListEmpty(),
      ],
    );
  });
}
