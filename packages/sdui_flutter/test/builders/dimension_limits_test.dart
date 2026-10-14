import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

Future<void> _pump(WidgetTester tester, SduiNode node) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          // Constraint frouxa: um pai tight de 300 não deixa o filho encolher.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
            child: SduiView(node: node),
          ),
        ),
      ),
    ),
  );
}

final Finder _inner = find
    .descendant(of: find.byType(SduiView), matching: find.byType(Container))
    .first;

void main() {
  testWidgets('container com maxWidth 100 em pai de 300 renderiza com 100', (
    tester,
  ) async {
    await _pump(
      tester,
      const SduiNode(
        id: 'c',
        type: 'container',
        properties: {'width': 'inf', 'maxWidth': 100, 'height': 50},
      ),
    );
    final size = tester.getSize(_inner);
    expect(size.width, 100);
  });

  testWidgets('sizedBox com maxWidth 100 em pai de 300 renderiza com 100', (
    tester,
  ) async {
    await _pump(
      tester,
      const SduiNode(
        id: 's',
        type: 'sizedBox',
        properties: {'width': 'inf', 'maxWidth': 100, 'height': 40},
        child: SduiNode(
          id: 'k',
          type: 'container',
          properties: {'width': 'inf', 'height': 'inf'},
        ),
      ),
    );
    expect(tester.getSize(_inner).width, 100);
  });
}
