import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

ContentSpec _loadFixtureContent() {
  final local = File('../sdui_core/test/fixtures/content_valid.json');
  final file = local.existsSync()
      ? local
      : File('packages/sdui_core/test/fixtures/content_valid.json');
  final json = (jsonDecode(file.readAsStringSync()) as Map)
      .cast<String, dynamic>();
  return parseContentSpec(json).getRight().toNullable()!;
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

  testWidgets('renderiza o conteúdo da fixture de ponta a ponta', (
    tester,
  ) async {
    await tester.pumpWidget(_host(SduiView.content(_loadFixtureContent())));

    expect(find.text('Semana do cliente'), findsOneWidget);
    expect(find.text('Ofertas selecionadas'), findsOneWidget);
    expect(find.text('Ver todas as ofertas'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Receber novidades'), findsOneWidget);
    expect(find.text('Aceito os termos'), findsOneWidget);
  });

  testWidgets('conteúdo sem root (vazio) renderiza nada, sem quebrar', (
    tester,
  ) async {
    const content = ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_vazio',
      name: 'Vazio',
      slug: 'vazio',
    );

    await tester.pumpWidget(_host(SduiView.content(content)));

    expect(tester.takeException(), isNull);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('controles de formulário renderizam com label (list tiles)', (
    tester,
  ) async {
    const node = SduiNode(
      id: 'root',
      type: 'column',
      children: [
        SduiNode(
          id: 'tf',
          type: 'textField',
          properties: {'label': 'Nome', 'value': 'Ana'},
        ),
        SduiNode(
          id: 'sw',
          type: 'switch',
          properties: {'value': true, 'label': 'Ativo'},
        ),
        SduiNode(
          id: 'cb',
          type: 'checkbox',
          properties: {'value': true, 'label': 'Concordo'},
        ),
      ],
    );

    await tester.pumpWidget(_host(const SduiView(node: node)));

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.initialValue, 'Ana');

    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
  });

  testWidgets('textField mapeia borderStyle nas três variantes', (
    tester,
  ) async {
    Future<InputDecoration> decorationFor(String borderStyle) async {
      final node = SduiNode(
        id: 'tf',
        type: 'textField',
        properties: {'label': 'X', 'borderStyle': borderStyle},
      );
      await tester.pumpWidget(_host(SduiView(node: node)));
      return tester.widget<TextField>(find.byType(TextField)).decoration!;
    }

    final outline = await decorationFor('outline');
    expect(outline.border, isA<OutlineInputBorder>());
    expect(outline.filled, isFalse);

    final underline = await decorationFor('underline');
    expect(underline.border, isA<UnderlineInputBorder>());
    expect(underline.filled, isFalse);

    final filled = await decorationFor('filled');
    expect(filled.border, isA<OutlineInputBorder>());
    expect(filled.filled, isTrue);
  });

  testWidgets('textField aplica keyboardType, maxLength e prefixIcon', (
    tester,
  ) async {
    const node = SduiNode(
      id: 'tf',
      type: 'textField',
      properties: {
        'label': 'Telefone',
        'keyboardType': 'phone',
        'maxLength': 11,
        'prefixIcon': 'person',
      },
    );

    await tester.pumpWidget(_host(const SduiView(node: node)));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.phone);
    expect(field.maxLength, 11);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('switch e checkbox sem label caem no controle simples', (
    tester,
  ) async {
    const node = SduiNode(
      id: 'root',
      type: 'row',
      children: [
        SduiNode(id: 'sw', type: 'switch', properties: {'value': false}),
        SduiNode(id: 'cb', type: 'checkbox', properties: {'value': true}),
      ],
    );

    await tester.pumpWidget(_host(const SduiView(node: node)));

    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
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
