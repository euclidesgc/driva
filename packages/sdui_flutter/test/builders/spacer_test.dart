import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

const _spacerNode = SduiNode(id: 's1', type: 'spacer', properties: {'flex': 2});

Future<void> _pump(WidgetTester tester, SduiNode node) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SduiView(node: node)),
    ),
  );
}

void main() {
  testWidgets('dentro de um Column vira Spacer de verdade', (tester) async {
    await _pump(
      tester,
      const SduiNode(
        id: 'c1',
        type: 'column',
        children: [
          SduiNode(id: 't1', type: 'text', properties: {'data': 'Oi'}),
          _spacerNode,
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.widget<Spacer>(find.byType(Spacer)).flex, 2);
  });

  testWidgets('como raiz não derruba a árvore por ParentData', (tester) async {
    await _pump(tester, _spacerNode);

    expect(tester.takeException(), isNull);
    expect(find.byType(Spacer), findsNothing);
  });

  testWidgets('dentro de um Container (sem flex) não estoura', (tester) async {
    await _pump(
      tester,
      const SduiNode(id: 'ct1', type: 'container', child: _spacerNode),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Spacer), findsNothing);
  });
}
