import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

PageSpec _loadFixturePage() {
  // A fixture do sdui_core é o contrato compartilhado kernel ↔ renderer.
  final local = File('../sdui_core/test/fixtures/page_valid.json');
  final file = local.existsSync()
      ? local
      : File('packages/sdui_core/test/fixtures/page_valid.json');
  final json = (jsonDecode(file.readAsStringSync()) as Map)
      .cast<String, dynamic>();
  return parsePageSpec(json).getRight().toNullable()!;
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('contrato kernel ↔ renderer: todo tipo do catálogo tem builder', () {
    for (final type in widgetCatalog.keys) {
      expect(
        defaultRegistry.contains(type),
        isTrue,
        reason: 'catálogo tem "$type" mas o registry não',
      );
    }
    for (final type in defaultRegistry.types) {
      expect(
        widgetCatalog.containsKey(type),
        isTrue,
        reason: 'registry tem "$type" mas o catálogo não',
      );
    }
  });

  testWidgets('renderiza a página da fixture de ponta a ponta', (tester) async {
    await tester.pumpWidget(_host(SduiView.page(_loadFixturePage())));

    expect(find.text('Semana do cliente'), findsOneWidget);
    expect(find.text('Ofertas selecionadas'), findsOneWidget);
    expect(find.text('Ver todas as ofertas'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
  });

  testWidgets('props planas viram estilo (texto e container)', (tester) async {
    const node = SduiNode(
      id: 'root',
      type: 'container',
      properties: {'color': '#112233', 'borderRadius': 8.0},
      child: SduiNode(
        id: 't',
        type: 'text',
        properties: {
          'data': 'Olá',
          'fontSize': 22.0,
          'fontWeight': 'w700',
          'color': '#FF0000',
        },
      ),
    );

    await tester.pumpWidget(_host(const SduiView(node: node)));

    final text = tester.widget<Text>(find.text('Olá'));
    expect(text.style?.fontSize, 22.0);
    expect(text.style?.fontWeight, FontWeight.w700);
    expect(text.style?.color, const Color(0xFFFF0000));

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFF112233));
    expect(decoration.borderRadius, BorderRadius.circular(8));
  });

  testWidgets('onPressed do botão despacha a ação do spec', (tester) async {
    const node = SduiNode(
      id: 'b',
      type: 'button',
      properties: {'label': 'Comprar'},
      events: {
        'onPressed': [
          {
            'action': 'navigate',
            'params': {'to': '/carrinho'},
          },
        ],
      },
    );
    final dispatched = <SduiAction>[];

    await tester.pumpWidget(
      _host(SduiView(node: node, onAction: dispatched.add)),
    );
    await tester.tap(find.text('Comprar'));

    expect(dispatched, hasLength(1));
    expect(dispatched.single.type, 'navigate');
    expect(dispatched.single.params['to'], '/carrinho');
  });

  testWidgets('botão desabilitado não despacha', (tester) async {
    const node = SduiNode(
      id: 'b',
      type: 'button',
      properties: {'label': 'Comprar', 'enabled': false},
      events: {
        'onPressed': [
          {'action': 'navigate'},
        ],
      },
    );
    final dispatched = <SduiAction>[];

    await tester.pumpWidget(
      _host(SduiView(node: node, onAction: dispatched.add)),
    );
    await tester.tap(find.text('Comprar'), warnIfMissed: false);

    expect(dispatched, isEmpty);
  });

  testWidgets('nodeWrapper envolve todos os nós (gancho de seleção)', (
    tester,
  ) async {
    const node = SduiNode(
      id: 'root',
      type: 'column',
      children: [
        SduiNode(id: 'a', type: 'text', properties: {'data': 'a'}),
        SduiNode(id: 'b', type: 'text', properties: {'data': 'b'}),
      ],
    );
    final wrapped = <String>[];

    await tester.pumpWidget(
      _host(
        SduiView(
          node: node,
          nodeWrapper: (n, built) {
            wrapped.add(n.id);
            return built;
          },
        ),
      ),
    );

    expect(wrapped, containsAll(<String>['root', 'a', 'b']));
  });

  testWidgets('tipo fora do registry mostra fallback, não derruba o preview', (
    tester,
  ) async {
    const node = SduiNode(id: 'x', type: 'carousel3d');

    await tester.pumpWidget(_host(const SduiView(node: node)));

    expect(find.textContaining('carousel3d'), findsOneWidget);
  });
}
