import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/repositories/editor_layout_repository_impl.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  const key = 'editor.layout';

  Future<EditorLayoutRepositoryImpl> buildWith(
    Map<String, Object> initial,
  ) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return EditorLayoutRepositoryImpl(prefs);
  }

  group('getLayout', () {
    test('chave ausente devolve o padrão em Right (D12)', () async {
      final repo = await buildWith({});

      final result = await repo.getLayout();

      expect(result.getRight().toNullable(), const EditorLayoutSnapshot());
    });

    test('lê o layout persistido', () async {
      const saved = EditorLayoutSnapshot(
        leftPanelWidth: 340,
        leftPanelTab: EditorLeftPanelTab.tree,
        collapsedInspectorSections: {'Cor'},
      );
      final repo = await buildWith({});
      await repo.saveLayout(saved);

      final result = await repo.getLayout();

      // Equatable compara `runtimeType`: o que volta do storage é um
      // `EditorLayoutModel`, então o confronto é por `.props`.
      expect(result.getRight().toNullable()?.props, saved.props);
    });

    test('JSON malformado (lixo) vira Left(ValidationFailure) (D12)', () async {
      final repo = await buildWith({key: 'isto não é JSON'});

      final result = await repo.getLayout();

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test(
      'JSON válido mas fora do schema vira Left(ValidationFailure) (D12)',
      () async {
        final repo = await buildWith({
          key: '{"leftPanelWidth": "não é número"}',
        });

        final result = await repo.getLayout();

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      },
    );

    test(
      'JSON de um array (não objeto) vira Left(ValidationFailure)',
      () async {
        final repo = await buildWith({key: '[1, 2, 3]'});

        final result = await repo.getLayout();

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      },
    );
  });

  group('saveLayout', () {
    test('persiste e relê o mesmo layout', () async {
      const layout = EditorLayoutSnapshot(
        rightPanelCollapsed: true,
        collapsedPaletteGroups: {'layout'},
      );
      final repo = await buildWith({});

      final saved = await repo.saveLayout(layout);
      final read = await repo.getLayout();

      expect(saved.isRight(), isTrue);
      expect(read.getRight().toNullable()?.props, layout.props);
    });

    test('erro de escrita no storage vira Left(UnexpectedFailure)', () async {
      final prefs = MockSharedPreferences();
      when(
        () => prefs.setString(key, any()),
      ).thenThrow(Exception('disco cheio'));
      final repo = EditorLayoutRepositoryImpl(prefs);

      final result = await repo.saveLayout(const EditorLayoutSnapshot());

      expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
    });
  });
}
