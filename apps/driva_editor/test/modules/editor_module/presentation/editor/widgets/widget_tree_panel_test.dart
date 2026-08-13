import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/widget_tree.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  const root = SduiNode(
    id: 'root',
    type: 'column',
    children: [
      SduiNode(id: 'text', type: 'text'),
      SduiNode(id: 'button', type: 'button'),
    ],
  );

  Widget harness({
    String? selectedNodeId = 'root',
    ValueChanged<String>? onRemove,
    ValueChanged<String?>? onSelect,
    void Function(String nodeId, String parentId, int index)? onDropMoveAt,
    void Function(String nodeId, String targetId)? onDropMove,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: WidgetTreePanel(
          root: root,
          selectedNodeId: selectedNodeId,
          onSelect: onSelect ?? (_) {},
          onRemove: onRemove ?? (_) {},
          onDropNew: (_, _) {},
          onDropMove: onDropMove ?? (_, _) {},
          onDropNewAt: (_, _, _) {},
          onDropMoveAt: onDropMoveAt ?? (_, _, _) {},
        ),
      ),
    );
  }

  testWidgets('raiz selecionada mostra ação de remover', (tester) async {
    String? removed;
    await tester.pumpWidget(harness(onRemove: (id) => removed = id));

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(removed, 'root');
  });

  testWidgets('raiz também é origem de drag na árvore', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byType(Draggable<DragPayload>), findsNWidgets(3));
  });

  group('linha da página', () {
    testWidgets('encabeça a árvore e fica marcada sem nó selecionado', (
      tester,
    ) async {
      await tester.pumpWidget(harness(selectedNodeId: null));

      final row = tester.widget<PageTreeRow>(find.byType(PageTreeRow));
      expect(row.isSelected, isTrue);
      expect(find.text('Página · área segura'), findsOneWidget);
    });

    testWidgets('clicar nela limpa a seleção (volta para a página)', (
      tester,
    ) async {
      var chamou = false;
      String? recebido = 'root';
      await tester.pumpWidget(
        harness(
          onSelect: (id) {
            chamou = true;
            recebido = id;
          },
        ),
      );

      await tester.tap(find.byType(PageTreeRow));

      expect(chamou, isTrue);
      expect(recebido, isNull);
    });
  });

  group('frestas entre as linhas', () {
    testWidgets('há uma fresta por posição possível da lista de filhos', (
      tester,
    ) async {
      await tester.pumpWidget(harness());

      // 2 filhos na column da raiz => 3 posições (antes, meio, depois).
      expect(find.byType(TreeGapDropZone), findsNWidgets(3));
    });

    testWidgets('soltar na primeira fresta pede o índice 0', (tester) async {
      String? movido;
      String? pai;
      int? indice;
      await tester.pumpWidget(
        harness(
          onDropMoveAt: (nodeId, parentId, index) {
            movido = nodeId;
            pai = parentId;
            indice = index;
          },
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Button')),
      );
      await tester.pump();
      await gesture.moveTo(
        tester.getCenter(find.byType(TreeGapDropZone).first),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(movido, 'button');
      expect(pai, 'root');
      expect(indice, 0);
    });
  });

  testWidgets('soltar sobre uma linha manda o alvo, não o índice', (
    tester,
  ) async {
    String? movido;
    String? alvo;
    await tester.pumpWidget(
      harness(
        onDropMove: (nodeId, targetId) {
          movido = nodeId;
          alvo = targetId;
        },
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Button')),
    );
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('Text')));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(movido, 'button');
    expect(alvo, 'text');
  });
}
