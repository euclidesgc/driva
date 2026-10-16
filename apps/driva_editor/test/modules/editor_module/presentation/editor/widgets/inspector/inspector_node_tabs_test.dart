import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector_node_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({required String node}) => MaterialApp(
  home: Scaffold(
    body: InspectorNodeTabs(
      properties: Text('props de $node'),
      actions: Text('ações de $node'),
    ),
  ),
);

void main() {
  group('InspectorNodeTabs', () {
    testWidgets('mostra as duas abas e começa em Propriedades', (
      tester,
    ) async {
      await tester.pumpWidget(_host(node: 'a'));

      expect(find.widgetWithText(Tab, 'Propriedades'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Ações'), findsOneWidget);
      expect(find.text('props de a'), findsOneWidget);
      expect(find.text('ações de a'), findsNothing);
    });

    testWidgets('tocar em Ações mostra o corpo de ações', (tester) async {
      await tester.pumpWidget(_host(node: 'a'));

      await tester.tap(find.widgetWithText(Tab, 'Ações'));
      await tester.pumpAndSettle();

      expect(find.text('ações de a'), findsOneWidget);
      expect(find.text('props de a'), findsNothing);
    });

    testWidgets('trocar de nó com Ações ativa mantém a aba', (tester) async {
      await tester.pumpWidget(_host(node: 'a'));
      await tester.tap(find.widgetWithText(Tab, 'Ações'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_host(node: 'b'));
      await tester.pumpAndSettle();

      expect(find.text('ações de b'), findsOneWidget);
      expect(find.text('props de b'), findsNothing);
    });
  });
}
