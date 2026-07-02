import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockEditorRepository extends Mock implements EditorRepository {}

void main() {
  late MockEditorRepository repository;
  late SaveDraftUseCase useCase;

  const validPage = PageSpec(
    specVersion: kSpecVersion,
    id: 'pg_1',
    name: 'Home',
    screenTarget: 'home',
    root: SduiNode(id: 'nd_root', type: 'column'),
  );

  setUpAll(() => registerFallbackValue(validPage));

  setUp(() {
    repository = MockEditorRepository();
    useCase = SaveDraftUseCase(repository: repository);
  });

  test('persiste um spec válido', () async {
    when(() => repository.saveDraft(any()))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(validPage);

    expect(result.isRight(), isTrue);
    verify(() => repository.saveDraft(validPage)).called(1);
  });

  test('barra spec que o kernel rejeitaria, sem tocar o repositório',
      () async {
    // root que não é column: o editor nunca produz isso; a trava garante.
    const invalid = PageSpec(
      specVersion: kSpecVersion,
      id: 'pg_1',
      name: 'Home',
      screenTarget: 'home',
      root: SduiNode(id: 'nd_root', type: 'row'),
    );

    final result = await useCase(invalid);

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.saveDraft(any()));
  });
}
