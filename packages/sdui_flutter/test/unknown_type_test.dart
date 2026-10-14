import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

void main() {
  testWidgets('nó de tipo desconhecido não derruba os irmãos', (tester) async {
    final content = parseContentSpec({
      'specVersion': 1,
      'kind': 'content',
      'id': 'ct_1',
      'name': 'T',
      'slug': 't',
      'root': {
        'id': 'n1',
        'type': 'column',
        'children': [
          {
            'id': 'n2',
            'type': 'text',
            'props': {'data': 'antes'},
          },
          {'id': 'n3', 'type': 'futureWidget'},
          {
            'id': 'n4',
            'type': 'text',
            'props': {'data': 'depois'},
          },
        ],
      },
    }, tolerant: true).toNullable()!;

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SduiView.content(content))),
    );

    expect(find.text('antes'), findsOneWidget);
    expect(find.text('depois'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
