import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockEditorRepository extends Mock implements EditorRepository {}

void main() {
  late MockEditorRepository repository;
  late GetContentVersionUseCase useCase;

  const spec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
  );
  final loaded = LoadedContentVersion(
    version: 3,
    spec: spec,
    createdAt: DateTime(2026, 8, 16),
  );

  setUp(() {
    repository = MockEditorRepository();
    useCase = GetContentVersionUseCase(repository: repository);
  });

  test('delega ao repositório e devolve a versão carregada', () async {
    when(
      () => repository.getVersion('ct_1', 3),
    ).thenAnswer((_) async => Right(loaded));

    final result = await useCase('ct_1', 3);

    expect(result, Right<Failure, LoadedContentVersion>(loaded));
    verify(() => repository.getVersion('ct_1', 3)).called(1);
  });

  test('propaga a falha do repositório sem tratar', () async {
    when(
      () => repository.getVersion('ct_1', 3),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase('ct_1', 3);

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });
}
