import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

Map<String, dynamic> _bind({Object? fallback, Object? preview}) => {
  r'$bind': {
    'source': BindingSourceIds.pageParam,
    'path': 'nome',
    'fallback': ?fallback,
    'preview': ?preview,
  },
};

Future<void> _pump(
  WidgetTester tester,
  SduiNode node, {
  BoundValueDisplay display = BoundValueDisplay.fallback,
  SduiNodeWrapper? nodeWrapper,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SduiView(
          node: node,
          boundValueDisplay: display,
          nodeWrapper: nodeWrapper,
        ),
      ),
    ),
  );
}

void main() {
  final cases = <(String, String, Object?)>[
    ('checkbox', 'value', true),
    ('dropdown', 'value', 'a'),
    ('radio', 'selected', true),
    ('switch', 'value', true),
    ('textField', 'value', 'abc'),
    ('button', 'label', 'Ok'),
    ('image', 'src', 'https://example.com/a.png'),
    ('text', 'data', 'Oi'),
  ];

  group(r'$bind na prop principal', () {
    for (final (type, key, fallback) in cases) {
      testWidgets('$type.$key sem fallback não lança', (tester) async {
        await _pump(
          tester,
          SduiNode(id: 'n', type: type, properties: {key: _bind()}),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('$type.$key com fallback não lança', (tester) async {
        await _pump(
          tester,
          SduiNode(
            id: 'n',
            type: type,
            properties: {key: _bind(fallback: fallback)},
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('boundValueDisplay', () {
    final node = SduiNode(
      id: 't',
      type: 'text',
      properties: {'data': _bind(fallback: 'Visitante', preview: 'Maria')},
    );

    testWidgets('fallback mostra o fallback', (tester) async {
      await _pump(tester, node);

      expect(find.text('Visitante'), findsOneWidget);
      expect(find.text('Maria'), findsNothing);
    });

    testWidgets('preview mostra o preview', (tester) async {
      await _pump(tester, node, display: BoundValueDisplay.preview);

      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Visitante'), findsNothing);
    });
  });

  testWidgets('checkbox com value legado "{{x}}" desenha sem exceção', (
    tester,
  ) async {
    await _pump(
      tester,
      const SduiNode(id: 'c', type: 'checkbox', properties: {'value': '{{x}}'}),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets(r'nodeWrapper recebe o nó original, com o $bind', (tester) async {
    final bound = _bind(fallback: 'Visitante');
    SduiNode? received;

    await _pump(
      tester,
      SduiNode(id: 't', type: 'text', properties: {'data': bound}),
      nodeWrapper: (node, built) {
        received = node;
        return built;
      },
    );

    expect(received?.properties['data'], bound);
    expect(find.text('Visitante'), findsOneWidget);
  });
}
