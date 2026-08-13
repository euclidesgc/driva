import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

const _expandedNode = SduiNode(
  id: 'e1',
  type: 'expanded',
  properties: {'flex': 3},
  child: SduiNode(id: 't1', type: 'text', properties: {'data': 'Oi'}),
);

Future<void> _pump(WidgetTester tester, SduiNode node) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SduiView(node: node)),
    ),
  );
}

void main() {
  testWidgets('dentro de um Column vira Expanded de verdade', (tester) async {
    await _pump(
      tester,
      const SduiNode(
        id: 'c1',
        type: 'column',
        children: [_expandedNode],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.widget<Expanded>(find.byType(Expanded)).flex, 3);
  });

  testWidgets('dentro de um Row vira Expanded de verdade', (tester) async {
    await _pump(
      tester,
      const SduiNode(
        id: 'r1',
        type: 'row',
        children: [_expandedNode],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Expanded), findsOneWidget);
  });

  testWidgets('como raiz, desenha só o filho em vez de derrubar a árvore', (
    tester,
  ) async {
    await _pump(tester, _expandedNode);

    expect(tester.takeException(), isNull);
    expect(find.byType(Expanded), findsNothing);
    expect(find.text('Oi'), findsOneWidget);
  });

  testWidgets('dentro de um Container (sem flex) não estoura', (tester) async {
    await _pump(
      tester,
      const SduiNode(
        id: 'ct1',
        type: 'container',
        child: _expandedNode,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Expanded), findsNothing);
    expect(find.text('Oi'), findsOneWidget);
  });

  testWidgets('o escopo não vaza para netos fora do flex', (tester) async {
    await _pump(
      tester,
      const SduiNode(
        id: 'c1',
        type: 'column',
        children: [
          SduiNode(
            id: 'ct1',
            type: 'container',
            child: _expandedNode,
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Expanded), findsNothing);
  });
}
