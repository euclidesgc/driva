import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_review_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_review_target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

class MockGetContentCheckpointUseCase extends Mock
    implements GetContentCheckpointUseCase {}

void main() {
  late MockGetContentVersionUseCase getContentVersion;
  late MockGetContentCheckpointUseCase getContentCheckpoint;

  const spec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
  );
  final loaded = LoadedContentVersion(
    version: 3,
    spec: spec,
    createdAt: DateTime.utc(2026, 8, 16),
    note: 'Ajuste no banner',
  );
  final loadedCheckpoint = LoadedContentCheckpoint(
    id: 'cp_1',
    spec: spec,
    createdAt: DateTime.utc(2026, 8, 16),
    note: 'Antes do lançamento',
  );

  setUp(() {
    getContentVersion = MockGetContentVersionUseCase();
    getContentCheckpoint = MockGetContentCheckpointUseCase();
  });

  VersionReviewCubit build() => VersionReviewCubit(
    getContentVersionUseCase: getContentVersion,
    contentId: 'ct_1',
    target: const PublishedVersionTarget(3),
  );

  group('load — publicação', () {
    blocTest<VersionReviewCubit, VersionReviewState>(
      'sucesso: emite Loading e a versão carregada, uma única requisição',
      build: build,
      setUp: () => when(
        () => getContentVersion('ct_1', 3),
      ).thenAnswer((_) async => Right(loaded)),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionReviewLoading(),
        VersionReviewLoaded(entry: loaded),
      ],
      verify: (_) => verify(() => getContentVersion('ct_1', 3)).called(1),
    );

    blocTest<VersionReviewCubit, VersionReviewState>(
      '404: mostra o estado de erro em vez de travar em Loading',
      build: build,
      setUp: () => when(
        () => getContentVersion('ct_1', 3),
      ).thenAnswer((_) async => const Left(NotFoundFailure())),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionReviewLoading(),
        const VersionReviewLoadFailure(failure: NotFoundFailure()),
      ],
    );

    blocTest<VersionReviewCubit, VersionReviewState>(
      'rede: mostra o estado de erro em vez de travar em Loading',
      build: build,
      setUp: () => when(
        () => getContentVersion('ct_1', 3),
      ).thenAnswer((_) async => const Left(NetworkFailure())),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionReviewLoading(),
        const VersionReviewLoadFailure(failure: NetworkFailure()),
      ],
    );

    blocTest<VersionReviewCubit, VersionReviewState>(
      'JSON inválido: mostra o estado de erro em vez de travar em Loading',
      build: build,
      setUp: () => when(() => getContentVersion('ct_1', 3)).thenAnswer(
        (_) async => const Left(ValidationFailure('spec ausente')),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionReviewLoading(),
        const VersionReviewLoadFailure(
          failure: ValidationFailure('spec ausente'),
        ),
      ],
    );
  });

  group('load — ponto salvo', () {
    VersionReviewCubit buildCheckpoint() => VersionReviewCubit(
      getContentVersionUseCase: getContentVersion,
      getContentCheckpointUseCase: getContentCheckpoint,
      contentId: 'ct_1',
      target: const CheckpointTarget('cp_1'),
    );

    blocTest<VersionReviewCubit, VersionReviewState>(
      'sucesso: emite Loading e o checkpoint carregado, sem tocar no use '
      'case de versão',
      build: buildCheckpoint,
      setUp: () => when(
        () => getContentCheckpoint('ct_1', 'cp_1'),
      ).thenAnswer((_) async => Right(loadedCheckpoint)),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionReviewLoading(),
        VersionReviewLoaded(entry: loadedCheckpoint),
      ],
      verify: (_) {
        verify(() => getContentCheckpoint('ct_1', 'cp_1')).called(1);
        verifyZeroInteractions(getContentVersion);
      },
    );

    blocTest<VersionReviewCubit, VersionReviewState>(
      'falha ao buscar o checkpoint: mostra o estado de erro',
      build: buildCheckpoint,
      setUp: () => when(
        () => getContentCheckpoint('ct_1', 'cp_1'),
      ).thenAnswer((_) async => const Left(NotFoundFailure())),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionReviewLoading(),
        const VersionReviewLoadFailure(failure: NotFoundFailure()),
      ],
    );

    blocTest<VersionReviewCubit, VersionReviewState>(
      'sem GetContentCheckpointUseCase, um alvo de checkpoint sempre falha',
      build: () => VersionReviewCubit(
        getContentVersionUseCase: getContentVersion,
        contentId: 'ct_1',
        target: const CheckpointTarget('cp_1'),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionReviewLoading(),
        const VersionReviewLoadFailure(failure: UnexpectedFailure()),
      ],
    );
  });
}
