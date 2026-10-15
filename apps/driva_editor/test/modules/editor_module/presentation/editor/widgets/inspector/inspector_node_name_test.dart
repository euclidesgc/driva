import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector_panel.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_node_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../../support/golden.dart';

Future<void> _pump(
  WidgetTester tester,
  SduiNode node, {
  void Function(String, String?)? onRename,
}) async {
  tester.view.physicalSize = const Size(340, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: InspectorPanel(
          onBindProp: (_, _, _) {},
          onUnbindProp: (_, _) {},
          node: node,
          isRoot: false,
          safeArea: const {},
          contentName: 'Home',
          contentSlug: 'home',
          onUpdateProps: (_, _) {},
          onUpdateSafeAreaProps: (_) {},
          onRemove: (_) {},
          onWrap: (_) {},
          onRename: onRename,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await installTolerantGoldenComparator();
  });

  testWidgets('editar o nome no cabeçalho chama onRename com o id do nó', (
    tester,
  ) async {
    String? id;
    String? name;
    await _pump(
      tester,
      const SduiNode(id: 'nd_1', type: 'container'),
      onRename: (i, n) {
        id = i;
        name = n;
      },
    );

    await tester.enterText(find.byType(TextFormField).first, 'Cartão');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(id, 'nd_1');
    expect(name, 'Cartão');
  });

  test('renameNode muda o nome, não o id; vazio vira null', () {
    const root = SduiNode(id: 'r', type: 'container');
    final renamed = renameNode(root, 'r', '  Cartão ');
    expect(renamed.name, 'Cartão');
    expect(renamed.id, 'r');
    expect(renameNode(renamed, 'r', '   ').name, isNull);
  });

  test('a árvore mostra o nome do nó quando existe', () {
    const node = SduiNode(id: 'a', type: 'container', name: 'Cartão');
    expect(treeNodeLabel(node), 'Cartão');
    expect(
      treeNodeLabel(const SduiNode(id: 'a', type: 'container')),
      'Container',
    );
  });

  testWidgets('golden: inspector com container selecionado', (tester) async {
    await _pump(
      tester,
      const SduiNode(id: 'nd_1', type: 'container', name: 'Cartão'),
      onRename: (_, _) {},
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(InspectorPanel),
      matchesGoldenFile('goldens/inspector_container.png'),
    );
  });
}
