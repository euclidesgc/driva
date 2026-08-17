import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_history_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetContentVersionsUseCase extends Mock
    implements GetContentVersionsUseCase {}

void main() {
  late MockGetContentVersionsUseCase getContentVersions;

  final firstPage = ContentVersionsPage(
    items: [
      ContentVersion(version: 3, createdAt: DateTime.utc(2026, 8, 16)),
      ContentVersion(version: 2, createdAt: DateTime.utc(2026, 8, 15)),
    ],
    nextCursor: 'cursor_2',
  );

  final secondPage = ContentVersionsPage(
    items: [ContentVersion(version: 1, createdAt: DateTime.utc(2026, 8, 14))],
  );

  setUp(() {
    getContentVersions = MockGetContentVersionsUseCase();
  });

  VersionHistoryCubit build({int? publishedVersion}) => VersionHistoryCubit(
    getContentVersionsUseCase: getContentVersions,
    contentId: 'ct_1',
    publishedVersion: publishedVersion,
  );

  group('load', () {
    blocTest<VersionHistoryCubit, VersionHistoryState>(
      'sucesso: emite Loading e a primeira página com a versão publicada',
      build: () => build(publishedVersion: 3),
      setUp: () => when(
        () => getContentVersions('ct_1'),
      ).thenAnswer((_) async => Right(firstPage)),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionHistoryLoading(),
        VersionHistoryLoaded(
          versions: firstPage.items,
          publishedVersion: 3,
          nextCursor: 'cursor_2',
        ),
      ],
      verify: (_) => verify(() => getContentVersions('ct_1')).called(1),
    );

    blocTest<VersionHistoryCubit, VersionHistoryState>(
      'lista vazia: nunca publicado não tem versões nem próxima página',
      build: build,
      setUp: () => when(
        () => getContentVersions('ct_1'),
      ).thenAnswer((_) async => const Right(ContentVersionsPage(items: []))),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionHistoryLoading(),
        const VersionHistoryLoaded(versions: []),
      ],
      verify: (cubit) {
        final state = cubit.state as VersionHistoryLoaded;
        expect(state.hasMore, isFalse);
      },
    );

    blocTest<VersionHistoryCubit, VersionHistoryState>(
      'falha: mostra o estado de erro em vez de travar em Loading',
      build: build,
      setUp: () => when(
        () => getContentVersions('ct_1'),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionHistoryLoading(),
        const VersionHistoryLoadFailure(failure: NetworkFailure()),
      ],
    );
  });

  group('loadMore', () {
    VersionHistoryCubit buildLoaded() => build(publishedVersion: 3)
      ..emit(
        VersionHistoryLoaded(
          versions: firstPage.items,
          publishedVersion: 3,
          nextCursor: firstPage.nextCursor,
        ),
      );

    blocTest<VersionHistoryCubit, VersionHistoryState>(
      'sucesso: pagina por cursor sem perder os itens já carregados',
      build: buildLoaded,
      setUp: () => when(
        () => getContentVersions('ct_1', cursor: 'cursor_2'),
      ).thenAnswer((_) async => Right(secondPage)),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        VersionHistoryLoaded(
          versions: firstPage.items,
          publishedVersion: 3,
          nextCursor: 'cursor_2',
          isLoadingMore: true,
        ),
        VersionHistoryLoaded(
          versions: [...firstPage.items, ...secondPage.items],
          publishedVersion: 3,
        ),
      ],
      verify: (_) => verify(
        () => getContentVersions('ct_1', cursor: 'cursor_2'),
      ).called(1),
    );

    blocTest<VersionHistoryCubit, VersionHistoryState>(
      'falha: volta a isLoadingMore false sem perder os itens já carregados',
      build: buildLoaded,
      setUp: () => when(
        () => getContentVersions('ct_1', cursor: 'cursor_2'),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        VersionHistoryLoaded(
          versions: firstPage.items,
          publishedVersion: 3,
          nextCursor: 'cursor_2',
          isLoadingMore: true,
        ),
        VersionHistoryLoaded(
          versions: firstPage.items,
          publishedVersion: 3,
          nextCursor: 'cursor_2',
        ),
      ],
    );

    blocTest<VersionHistoryCubit, VersionHistoryState>(
      'sem próxima página: não chama o use case de novo',
      build: () => build(publishedVersion: 3)
        ..emit(
          VersionHistoryLoaded(versions: firstPage.items, publishedVersion: 3),
        ),
      act: (cubit) => cubit.loadMore(),
      expect: () => <VersionHistoryState>[],
      verify: (_) => verifyNever(
        () => getContentVersions(any(), cursor: any(named: 'cursor')),
      ),
    );
  });
}
