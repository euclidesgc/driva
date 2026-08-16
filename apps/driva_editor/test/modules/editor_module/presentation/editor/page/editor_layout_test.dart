import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorLayout', () {
    test('padrão nasce com os dois painéis expandidos na aba Widgets', () {
      const layout = EditorLayout();

      expect(layout.leftPanelCollapsed, isFalse);
      expect(layout.rightPanelCollapsed, isFalse);
      expect(layout.leftPanelTab, LeftPanelTab.widgets);
    });

    test('duas instâncias com os mesmos campos são iguais', () {
      const a = EditorLayout(
        leftPanelCollapsed: true,
        rightPanelCollapsed: true,
        leftPanelTab: LeftPanelTab.tree,
      );
      const b = EditorLayout(
        leftPanelCollapsed: true,
        rightPanelCollapsed: true,
        leftPanelTab: LeftPanelTab.tree,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('instâncias com campos diferentes não são iguais', () {
      const a = EditorLayout();
      const b = EditorLayout(leftPanelCollapsed: true);

      expect(a, isNot(equals(b)));
    });

    group('copyWith', () {
      test('sem argumentos preserva todos os campos', () {
        const original = EditorLayout(
          leftPanelCollapsed: true,
          rightPanelCollapsed: true,
          leftPanelTab: LeftPanelTab.tree,
        );

        expect(original.copyWith(), equals(original));
      });

      test('troca só o campo informado', () {
        const original = EditorLayout();

        final changed = original.copyWith(leftPanelCollapsed: true);

        expect(changed.leftPanelCollapsed, isTrue);
        expect(changed.rightPanelCollapsed, original.rightPanelCollapsed);
        expect(changed.leftPanelTab, original.leftPanelTab);
      });

      test('troca a aba corrente sem afetar o colapso dos painéis', () {
        const original = EditorLayout(rightPanelCollapsed: true);

        final changed = original.copyWith(leftPanelTab: LeftPanelTab.tree);

        expect(changed.leftPanelTab, LeftPanelTab.tree);
        expect(changed.leftPanelCollapsed, original.leftPanelCollapsed);
        expect(changed.rightPanelCollapsed, original.rightPanelCollapsed);
      });
    });
  });
}
