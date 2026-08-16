import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/models/editor_layout_model.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validMap = {
    'leftPanelWidth': 300.0,
    'rightPanelWidth': 340.0,
    'leftPanelCollapsed': true,
    'rightPanelCollapsed': false,
    'leftPanelTab': 'tree',
    'collapsedPaletteGroups': ['layout'],
    'collapsedInspectorSections': ['Cor', 'Texto'],
  };

  group('tryParse', () {
    test('mapa válido devolve o snapshot equivalente', () {
      final result = EditorLayoutModel.tryParse(validMap);

      final layout = result.getRight().toNullable();
      expect(layout, isNotNull);
      // Equatable compara `runtimeType`: `EditorLayoutModel` nunca é ==
      // a um `EditorLayoutSnapshot` puro, então o confronto é por `.props`.
      expect(
        layout!.props,
        const EditorLayoutSnapshot(
          leftPanelWidth: 300,
          rightPanelWidth: 340,
          leftPanelCollapsed: true,
          leftPanelTab: EditorLeftPanelTab.tree,
          collapsedPaletteGroups: {'layout'},
          collapsedInspectorSections: {'Cor', 'Texto'},
        ).props,
      );
    });

    test('campo obrigatório ausente vira ValidationFailure', () {
      final map = Map<String, dynamic>.from(validMap)..remove('leftPanelWidth');

      final result = EditorLayoutModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('tipo incompatível (corrompido) vira ValidationFailure', () {
      final map = Map<String, dynamic>.from(validMap)
        ..['leftPanelCollapsed'] = 'sim';

      final result = EditorLayoutModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('aba fora do enum aceito vira ValidationFailure', () {
      final map = Map<String, dynamic>.from(validMap)
        ..['leftPanelTab'] = 'inexistente';

      final result = EditorLayoutModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test(
      'largura zero ou negativa (fora dos limites) vira ValidationFailure',
      () {
        final zero = Map<String, dynamic>.from(validMap)
          ..['leftPanelWidth'] = 0.0;
        final negative = Map<String, dynamic>.from(validMap)
          ..['rightPanelWidth'] = -10.0;

        expect(
          EditorLayoutModel.tryParse(zero).getLeft().toNullable(),
          isA<ValidationFailure>(),
        );
        expect(
          EditorLayoutModel.tryParse(negative).getLeft().toNullable(),
          isA<ValidationFailure>(),
        );
      },
    );
  });

  group('toJson', () {
    test('roda de volta em tryParse produzindo o mesmo snapshot', () {
      const layout = EditorLayoutSnapshot(
        leftPanelWidth: 260,
        rightPanelWidth: 300,
        rightPanelCollapsed: true,
        leftPanelTab: EditorLeftPanelTab.tree,
        collapsedPaletteGroups: {'básicos'},
        collapsedInspectorSections: {'Espaçamento'},
      );

      final json = EditorLayoutModel.toJson(layout);
      final result = EditorLayoutModel.tryParse(json);

      expect(result.getRight().toNullable()?.props, layout.props);
    });
  });
}
