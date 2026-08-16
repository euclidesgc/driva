import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorLayoutSnapshot', () {
    test('padrão nasce em 280/320, tudo expandido, aba Widgets', () {
      const layout = EditorLayoutSnapshot();

      expect(layout.leftPanelWidth, 280);
      expect(layout.rightPanelWidth, 320);
      expect(layout.leftPanelCollapsed, isFalse);
      expect(layout.rightPanelCollapsed, isFalse);
      expect(layout.leftPanelTab, EditorLeftPanelTab.widgets);
      expect(layout.collapsedPaletteGroups, isEmpty);
      expect(layout.collapsedInspectorSections, isEmpty);
    });

    test('duas instâncias com os mesmos campos são iguais', () {
      const a = EditorLayoutSnapshot(
        leftPanelWidth: 300,
        rightPanelWidth: 340,
        leftPanelCollapsed: true,
        rightPanelCollapsed: true,
        leftPanelTab: EditorLeftPanelTab.tree,
        collapsedPaletteGroups: {'layout'},
        collapsedInspectorSections: {'Espaçamento'},
      );
      const b = EditorLayoutSnapshot(
        leftPanelWidth: 300,
        rightPanelWidth: 340,
        leftPanelCollapsed: true,
        rightPanelCollapsed: true,
        leftPanelTab: EditorLeftPanelTab.tree,
        collapsedPaletteGroups: {'layout'},
        collapsedInspectorSections: {'Espaçamento'},
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('instâncias com campos diferentes não são iguais', () {
      const a = EditorLayoutSnapshot();
      const b = EditorLayoutSnapshot(leftPanelWidth: 300);

      expect(a, isNot(equals(b)));
    });

    test('conjuntos diferentes de seções colapsadas quebram a igualdade', () {
      const a = EditorLayoutSnapshot(collapsedInspectorSections: {'Cor'});
      const b = EditorLayoutSnapshot(collapsedInspectorSections: {'Texto'});

      expect(a, isNot(equals(b)));
    });

    group('copyWith', () {
      test('sem argumentos preserva todos os campos', () {
        const original = EditorLayoutSnapshot(
          leftPanelWidth: 300,
          rightPanelCollapsed: true,
          leftPanelTab: EditorLeftPanelTab.tree,
          collapsedPaletteGroups: {'layout'},
          collapsedInspectorSections: {'Cor'},
        );

        expect(original.copyWith(), equals(original));
      });

      test('troca só o campo informado', () {
        const original = EditorLayoutSnapshot();

        final changed = original.copyWith(leftPanelWidth: 340);

        expect(changed.leftPanelWidth, 340);
        expect(changed.rightPanelWidth, original.rightPanelWidth);
        expect(changed.leftPanelCollapsed, original.leftPanelCollapsed);
        expect(
          changed.collapsedInspectorSections,
          original.collapsedInspectorSections,
        );
      });

      test('troca as seções do Inspector sem afetar as larguras', () {
        const original = EditorLayoutSnapshot(leftPanelWidth: 300);

        final changed = original.copyWith(
          collapsedInspectorSections: {'Cor', 'Texto'},
        );

        expect(changed.collapsedInspectorSections, {'Cor', 'Texto'});
        expect(changed.leftPanelWidth, original.leftPanelWidth);
      });
    });
  });
}
