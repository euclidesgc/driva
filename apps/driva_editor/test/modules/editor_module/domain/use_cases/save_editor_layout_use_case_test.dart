import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_layout_repository.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEditorLayoutRepository extends Mock
    implements EditorLayoutRepository {}

void main() {
  late MockEditorLayoutRepository repository;
  late SaveEditorLayoutUseCase useCase;

  const layout = EditorLayoutSnapshot(
    leftPanelWidth: 300,
    collapsedInspectorSections: {'Cor'},
  );

  setUpAll(() => registerFallbackValue(layout));

  setUp(() {
    repository = MockEditorLayoutRepository();
    useCase = SaveEditorLayoutUseCase(repository: repository);
  });

  test('delega o layout ao repositório sem alterá-lo', () async {
    when(
      () => repository.saveLayout(any()),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(layout);

    expect(result.isRight(), isTrue);
    verify(() => repository.saveLayout(layout)).called(1);
  });

  test('propaga a falha do repositório sem tratar', () async {
    when(
      () => repository.saveLayout(any()),
    ).thenAnswer((_) async => const Left(UnexpectedFailure('falhou')));

    final result = await useCase(layout);

    expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
  });
}
