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
    description: 'Vitrine',
    updatedAt: DateTime(2026, 7, 1),
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
      setUp: () =>
          when(() => getContents()).thenAnswer((_) async => Right([content])),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ContentListLoading(),
        ContentListLoaded(contents: [content]),
      ],
    );

    blocTest<ContentListCubit, ContentListState>(
      'emite Loading → Empty quando não há conteúdos',
      build: build,
      setUp: () =>
          when(() => getContents()).thenAnswer((_) async => const Right([])),
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

  group('create', () {
    blocTest<ContentListCubit, ContentListState>(
      'sucesso: recarrega a lista e devolve o conteúdo criado',
      build: build,
      setUp: () {
        when(
          () => createContent(name: 'Home', slug: 'home', description: null),
        ).thenAnswer((_) async => Right(content));
        when(() => getContents()).thenAnswer((_) async => Right([content]));
      },
      act: (cubit) => cubit.create(name: 'Home', slug: 'home'),
      expect: () => [
        const ContentListLoading(),
        ContentListLoaded(contents: [content]),
      ],
      verify: (_) => verify(() => getContents()).called(1),
    );

    blocTest<ContentListCubit, ContentListState>(
      'conflito: não recarrega e devolve ConflictFailure com sugestão',
      build: build,
      setUp: () => when(
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
      'recarrega após excluir',
      build: build,
      setUp: () {
        when(
          () => deleteContent('ct_1'),
        ).thenAnswer((_) async => const Right(unit));
        when(() => getContents()).thenAnswer((_) async => const Right([]));
      },
      act: (cubit) => cubit.delete('ct_1'),
      expect: () => [const ContentListLoading(), const ContentListEmpty()],
    );
  });
}
