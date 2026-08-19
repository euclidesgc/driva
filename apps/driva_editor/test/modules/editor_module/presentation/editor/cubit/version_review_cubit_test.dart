import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_review_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

void main() {
  late MockGetContentVersionUseCase getContentVersion;

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

  setUp(() {
    getContentVersion = MockGetContentVersionUseCase();
  });

  VersionReviewCubit build() => VersionReviewCubit(
    getContentVersionUseCase: getContentVersion,
    contentId: 'ct_1',
    version: 3,
  );

  group('load', () {
    blocTest<VersionReviewCubit, VersionReviewState>(
      'sucesso: emite Loading e a versão carregada, uma única requisição',
      build: build,
      setUp: () => when(
        () => getContentVersion('ct_1', 3),
      ).thenAnswer((_) async => Right(loaded)),
      act: (cubit) => cubit.load(),
      expect: () => [
        const VersionReviewLoading(),
        VersionReviewLoaded(version: loaded),
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
}
