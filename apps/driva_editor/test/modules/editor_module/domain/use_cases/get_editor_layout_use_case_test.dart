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
  late GetEditorLayoutUseCase useCase;

  setUp(() {
    repository = MockEditorLayoutRepository();
    useCase = GetEditorLayoutUseCase(repository: repository);
  });

  test('delega ao repositório e devolve o layout salvo', () async {
    const saved = EditorLayoutSnapshot(leftPanelWidth: 340);
    when(
      () => repository.getLayout(),
    ).thenAnswer((_) async => const Right(saved));

    final result = await useCase();

    expect(result, const Right<Failure, EditorLayoutSnapshot>(saved));
    verify(() => repository.getLayout()).called(1);
  });

  test('propaga a falha do repositório sem tratar', () async {
    when(
      () => repository.getLayout(),
    ).thenAnswer((_) async => const Left(ValidationFailure('corrompido')));

    final result = await useCase();

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });
}
