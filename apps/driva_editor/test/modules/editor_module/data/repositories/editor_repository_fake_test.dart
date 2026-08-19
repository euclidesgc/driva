import 'package:driva_editor/core/dev/fake_contents_store.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/repositories/editor_repository_fake.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeContentsStore store;
  late EditorRepositoryFake repository;

  setUp(() {
    store = FakeContentsStore();
    repository = EditorRepositoryFake(store);
  });

  group('getVersion', () {
    test(
      'sucesso: devolve LoadedContentVersion com o spec exato publicado',
      () async {
        store.publish('ct_exemplo', note: 'Primeira publicação');

        final result = await repository.getVersion('ct_exemplo', 1);

        final loaded = result.getRight().toNullable();
        expect(loaded, isA<LoadedContentVersion>());
        expect(loaded!.version, 1);
        expect(loaded.note, 'Primeira publicação');
        expect(loaded.spec.id, 'ct_exemplo');
      },
    );

    test('conteúdo inexistente vira Left(NotFoundFailure)', () async {
      final result = await repository.getVersion('ct_ghost', 1);

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test('versão inexistente vira Left(NotFoundFailure)', () async {
      store.publish('ct_exemplo');

      final result = await repository.getVersion('ct_exemplo', 99);

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });
}
