import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

Future<void> _pump(WidgetTester tester, Map<String, dynamic> json) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SduiView.fromJson(json))),
    );

void main() {
  testWidgets('Row renderiza filhos', (tester) async {
    await _pump(tester, {
      'type': 'row',
      'children': [
        {
          'type': 'text',
          'props': {'data': 'A'},
        },
        {
          'type': 'text',
          'props': {'data': 'B'},
        },
      ],
    });
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.byType(Row), findsOneWidget);
  });

  testWidgets('Stack + Positioned', (tester) async {
    await _pump(tester, {
      'type': 'stack',
      'children': [
        {
          'type': 'positioned',
          'props': {'left': 4, 'top': 8},
          'child': {
            'type': 'text',
            'props': {'data': 'P'},
          },
        },
      ],
    });
    expect(find.byType(Stack), findsWidgets);
    expect(find.byType(Positioned), findsOneWidget);
    expect(find.text('P'), findsOneWidget);
  });

  testWidgets('Container com decoration', (tester) async {
    await _pump(tester, {
      'type': 'container',
      'props': {
        'alignment': 'center',
        'decoration': {'color': '#FF1565C0', 'borderRadius': 8},
      },
      'child': {
        'type': 'text',
        'props': {'data': 'D'},
      },
    });
    expect(tester.takeException(), isNull);
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('Image produz um Image', (tester) async {
    await _pump(tester, {
      'type': 'image',
      'props': {'src': 'https://example.com/y.png', 'fit': 'cover'},
    });
    expect(find.byType(Image), findsOneWidget);
    tester.takeException(); // limpa o erro de rede esperado em ambiente de teste
  });

  testWidgets('Icon (subconjunto curado)', (tester) async {
    await _pump(tester, {
      'type': 'icon',
      'props': {'icon': 'home', 'size': 32},
    });
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('Button elevated com label', (tester) async {
    await _pump(tester, {
      'type': 'button',
      'props': {'label': 'OK'},
    });
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('SizedBox / Padding / Center com child', (tester) async {
    await _pump(tester, {
      'type': 'padding',
      'props': {
        'padding': {'all': 8},
      },
      'child': {
        'type': 'center',
        'child': {
          'type': 'sizedBox',
          'props': {'width': 10, 'height': 10},
          'child': {
            'type': 'text',
            'props': {'data': 'X'},
          },
        },
      },
    });
    expect(find.text('X'), findsOneWidget);
    expect(find.byType(Padding), findsWidgets);
    expect(find.byType(Center), findsWidgets);
  });

  testWidgets('Expanded / Spacer dentro de Row', (tester) async {
    await _pump(tester, {
      'type': 'row',
      'children': [
        {
          'type': 'expanded',
          'child': {
            'type': 'text',
            'props': {'data': 'E'},
          },
        },
        {'type': 'spacer'},
      ],
    });
    expect(find.byType(Expanded), findsWidgets);
    expect(find.byType(Spacer), findsOneWidget);
    expect(find.text('E'), findsOneWidget);
  });

  testWidgets('GestureDetector envolve o child', (tester) async {
    await _pump(tester, {
      'type': 'gestureDetector',
      'child': {
        'type': 'text',
        'props': {'data': 'toque'},
      },
    });
    expect(find.text('toque'), findsOneWidget);
  });
}
