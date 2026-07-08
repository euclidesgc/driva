import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
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
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: WidgetTreePanel(
          root: root,
          selectedNodeId: selectedNodeId,
          onSelect: (_) {},
          onRemove: onRemove ?? (_) {},
          onAddInto: (_, _, _) {},
          onMoveInto: (_, _, _) {},
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
}
