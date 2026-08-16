import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorLayoutController', () {
    test('nasce com o padrão quando nenhum layout inicial é informado', () {
      final controller = EditorLayoutController();

      expect(controller.value, const EditorLayout());
    });

    test('aceita um layout inicial diferente do padrão', () {
      const initial = EditorLayout(leftPanelCollapsed: true);

      final controller = EditorLayoutController(initial);

      expect(controller.value, initial);
    });

    test('collapseLeftPanel colapsa só o painel esquerdo e notifica', () {
      final controller = EditorLayoutController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.collapseLeftPanel();

      expect(controller.value.leftPanelCollapsed, isTrue);
      expect(controller.value.rightPanelCollapsed, isFalse);
      expect(notifications, 1);
    });

    test('expandLeftPanel expande o painel esquerdo e notifica', () {
      final controller = EditorLayoutController(
        const EditorLayout(leftPanelCollapsed: true),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.expandLeftPanel();

      expect(controller.value.leftPanelCollapsed, isFalse);
      expect(notifications, 1);
    });

    test('collapseRightPanel colapsa só o painel direito e notifica', () {
      final controller = EditorLayoutController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.collapseRightPanel();

      expect(controller.value.rightPanelCollapsed, isTrue);
      expect(controller.value.leftPanelCollapsed, isFalse);
      expect(notifications, 1);
    });

    test('expandRightPanel expande o painel direito e notifica', () {
      final controller = EditorLayoutController(
        const EditorLayout(rightPanelCollapsed: true),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.expandRightPanel();

      expect(controller.value.rightPanelCollapsed, isFalse);
      expect(notifications, 1);
    });

    test('setLeftPanelTab troca a aba sem alterar o colapso', () {
      final controller = EditorLayoutController(
        const EditorLayout(leftPanelCollapsed: true),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.setLeftPanelTab(LeftPanelTab.tree);

      expect(controller.value.leftPanelTab, LeftPanelTab.tree);
      expect(controller.value.leftPanelCollapsed, isTrue);
      expect(notifications, 1);
    });

    test(
      'showLeftPanelTab reabre o painel já na aba pedida (D2, aceite 26)',
      () {
        final controller = EditorLayoutController(
          const EditorLayout(leftPanelCollapsed: true),
        );
        var notifications = 0;
        controller.addListener(() => notifications++);
        expect(notifications, 0);

        controller.showLeftPanelTab(LeftPanelTab.tree);

        expect(controller.value.leftPanelCollapsed, isFalse);
        expect(controller.value.leftPanelTab, LeftPanelTab.tree);
        expect(notifications, 1);
      },
    );

    test('não notifica quando o novo valor é igual ao atual', () {
      final controller = EditorLayoutController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);

      controller.expandLeftPanel();

      expect(notifications, 0);
    });
  });
}
