import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';
import 'package:sdui_flutter/src/sdui_gesture_triggers.dart';

const List<Map<String, Object>> _navigatePromocoes = [
  {
    'action': 'navigate',
    'params': {'slug': 'promocoes'},
  },
];

const _expectedNavigate = SduiAction(
  type: 'navigate',
  params: {'slug': 'promocoes'},
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

SduiNode _tappable(String type, {Map<String, dynamic> events = const {}}) {
  return switch (type) {
    'container' => SduiNode(
      id: 'n',
      type: 'container',
      properties: const {'width': 80, 'height': 80, 'color': '#FF3366'},
      events: events,
    ),
    'card' => SduiNode(
      id: 'n',
      type: 'card',
      events: events,
      child: const SduiNode(
        id: 'n_text',
        type: 'text',
        properties: {'data': 'Cartão'},
      ),
    ),
    'text' => SduiNode(
      id: 'n',
      type: 'text',
      properties: const {'data': 'Toque aqui'},
      events: events,
    ),
    'image' => SduiNode(
      id: 'n',
      type: 'image',
      properties: const {'width': 80, 'height': 80},
      events: events,
    ),
    'icon' => SduiNode(
      id: 'n',
      type: 'icon',
      properties: const {'icon': 'star'},
      events: events,
    ),
    _ => throw ArgumentError(type),
  };
}

SduiNode _page({Map<String, dynamic> events = const {}}) => SduiNode(
  id: 'root',
  type: 'column',
  children: [
    _tappable('container', events: events),
    _tappable('text', events: events),
    const SduiNode(id: 'btn', type: 'button', properties: {'label': 'Comprar'}),
  ],
);

void main() {
  for (final type in ['container', 'card', 'text', 'image', 'icon']) {
    testWidgets('$type com onTap entrega a ação ao onAction', (tester) async {
      final received = <SduiAction>[];
      await tester.pumpWidget(
        _host(
          SduiView(
            node: _tappable(type, events: const {'onTap': _navigatePromocoes}),
            onAction: received.add,
          ),
        ),
      );

      await tester.tap(find.byType(SduiGestureTriggers));
      await tester.pump();

      expect(received, [_expectedNavigate]);
    });
  }

  testWidgets('card com onDoubleTap e onLongPress: cada gesto entrega só a '
      'sua ação', (tester) async {
    final received = <SduiAction>[];
    await tester.pumpWidget(
      _host(
        SduiView(
          node: _tappable(
            'card',
            events: const {
              'onDoubleTap': [
                {
                  'action': 'showSnackBar',
                  'params': {'message': 'duplo'},
                },
              ],
              'onLongPress': [
                {
                  'action': 'copyToClipboard',
                  'params': {'text': 'longo'},
                },
              ],
            },
          ),
          onAction: received.add,
        ),
      ),
    );
    final target = find.byType(SduiGestureTriggers);

    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(received, [
      const SduiAction(type: 'showSnackBar', params: {'message': 'duplo'}),
    ]);

    received.clear();
    await tester.longPress(target);
    await tester.pumpAndSettle();

    expect(received, [
      const SduiAction(type: 'copyToClipboard', params: {'text': 'longo'}),
    ]);
  });

  group('árvore sem detector a mais', () {
    Future<int> countDetectors(WidgetTester tester, Widget view) async {
      await tester.pumpWidget(_host(view));
      return find.byType(GestureDetector).evaluate().length;
    }

    testWidgets('nó sem events, com onAction, não ganha GestureDetector', (
      tester,
    ) async {
      final baseline = await countDetectors(tester, SduiView(node: _page()));
      final withHandler = await countDetectors(
        tester,
        SduiView(node: _page(), onAction: (_) {}),
      );

      expect(withHandler, baseline);
      expect(find.byType(SduiGestureTriggers), findsNothing);
    });

    testWidgets('nó com events, sem onAction, não ganha GestureDetector', (
      tester,
    ) async {
      final baseline = await countDetectors(tester, SduiView(node: _page()));
      final withoutHandler = await countDetectors(
        tester,
        SduiView(node: _page(events: const {'onTap': _navigatePromocoes})),
      );

      expect(withoutHandler, baseline);
      expect(find.byType(SduiGestureTriggers), findsNothing);
    });
  });

  testWidgets('onTap com lista vazia não monta detector nem despacha', (
    tester,
  ) async {
    final received = <SduiAction>[];
    await tester.pumpWidget(
      _host(
        SduiView(
          node: _tappable('container', events: const {'onTap': <Object>[]}),
          onAction: received.add,
        ),
      ),
    );

    expect(find.byType(SduiGestureTriggers), findsNothing);
    await tester.tap(find.byType(SduiView));
    await tester.pump();

    expect(received, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authoringMode: nó com onTap não ganha detector nem despacha', (
    tester,
  ) async {
    final received = <SduiAction>[];
    await tester.pumpWidget(
      _host(
        SduiView(
          node: _tappable(
            'container',
            events: const {'onTap': _navigatePromocoes},
          ),
          onAction: received.add,
          authoringMode: true,
        ),
      ),
    );

    expect(find.byType(SduiGestureTriggers), findsNothing);
    await tester.tap(find.byType(SduiView));
    await tester.pump();

    expect(received, isEmpty);
  });

  testWidgets('SduiView.content repassa o authoringMode ao renderer', (
    tester,
  ) async {
    final content = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct',
      name: 'Página',
      slug: 'pagina',
      root: _tappable('container', events: const {'onTap': _navigatePromocoes}),
    );

    await tester.pumpWidget(
      _host(SduiView.content(content, onAction: (_) {}, authoringMode: true)),
    );
    expect(find.byType(SduiGestureTriggers), findsNothing);

    await tester.pumpWidget(_host(SduiView.content(content, onAction: (_) {})));
    expect(find.byType(SduiGestureTriggers), findsOneWidget);
  });

  testWidgets('button com onPressed não ganha SduiGestureTriggers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SduiView(
          node: const SduiNode(
            id: 'btn',
            type: 'button',
            properties: {'label': 'Comprar'},
            events: {'onPressed': _navigatePromocoes},
          ),
          onAction: (_) {},
        ),
      ),
    );

    expect(find.byType(SduiGestureTriggers), findsNothing);
  });

  test('parseColor é exportado pelo barrel', () {
    expect(parseColor('#FF0000'), const Color(0xFFFF0000));
  });
}
