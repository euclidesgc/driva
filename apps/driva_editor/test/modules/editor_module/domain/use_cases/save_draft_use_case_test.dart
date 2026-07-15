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

  const validContent = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(id: 'nd_root', type: 'column'),
  );

  setUpAll(() => registerFallbackValue(validContent));

  setUp(() {
    repository = MockEditorRepository();
    useCase = SaveDraftUseCase(repository: repository);
  });

  test('persiste um spec válido', () async {
    when(
      () => repository.saveDraft(any()),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(validContent);

    expect(result.isRight(), isTrue);
    verify(() => repository.saveDraft(validContent)).called(1);
  });

  test('barra spec que o kernel rejeitaria, sem tocar o repositório', () async {
    // Inválido: `text` é folha, não aceita children.
    const invalid = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_1',
      name: 'Home',
      slug: 'home',
      root: SduiNode(
        id: 'nd_root',
        type: 'text',
        properties: {'data': 'oi'},
        children: [SduiNode(id: 'nd_x', type: 'text')],
      ),
    );

    final result = await useCase(invalid);

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.saveDraft(any()));
  });

  test('persiste um conteúdo vazio (sem root)', () async {
    const empty = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_1',
      name: 'Home',
      slug: 'home',
    );
    when(
      () => repository.saveDraft(any()),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(empty);

    expect(result.isRight(), isTrue);
    verify(() => repository.saveDraft(empty)).called(1);
  });
}
