import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

void main() {
  testWidgets('renderiza container > column > [text, text]', (tester) async {
    final json = {
      'type': 'container',
      'props': {
        'padding': {'all': 16},
        'color': '#FFFFFF',
      },
      'child': {
        'type': 'column',
        'props': {'spacing': 8},
        'children': [
          {
            'type': 'text',
            'props': {
              'data': 'Título',
              'style': {'fontSize': 18, 'fontWeight': 'w600'},
            },
          },
          {
            'type': 'text',
            'props': {'data': 'Subtítulo'},
          },
        ],
      },
    };

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SduiView.fromJson(json))),
    );

    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Subtítulo'), findsOneWidget);
  });

  testWidgets('tipo desconhecido não quebra a árvore', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SduiView.fromJson(const {'type': 'naoexiste'})),
    );
    expect(tester.takeException(), isNull);
  });
}
