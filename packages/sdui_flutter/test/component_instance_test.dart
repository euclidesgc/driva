import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

ContentSpec _component(String id, SduiNode root, {bool required = true}) =>
    ContentSpec(
      specVersion: 2,
      id: id,
      name: 'Cartao',
      slug: id,
      kind: ContentKind.component,
      params: [
        ComponentParam(
          name: 'titulo',
          type: ComponentParamType.text,
          isList: false,
          isRequired: required,
        ),
      ],
      root: root,
    );

SduiNode _instance(String componentId, [Map<String, dynamic>? args]) =>
    SduiNode(
      id: 'inst1',
      type: ComponentInstance.type,
      properties: {
        ComponentInstance.componentIdKey: componentId,
        ComponentInstance.argsKey: ?args,
      },
    );

const _tituloText = SduiNode(
  id: 'texto',
  type: 'text',
  properties: {
    'data': {
      r'$bind': {
        'source': BindingSourceIds.componentParam,
        'path': 'titulo',
      },
    },
  },
);

Future<void> _pump(
  WidgetTester tester,
  SduiNode node, {
  Map<String, ContentSpec>? components,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SduiView(
        node: node,
        componentLookup: components == null ? null : (id) => components[id],
      ),
    ),
  ),
);

void main() {
  final card = _component('cp_1', _tituloText);

  testWidgets('instância renderiza o arg ligado por componentParam', (
    tester,
  ) async {
    await _pump(
      tester,
      _instance('cp_1', {'titulo': 'Olá'}),
      components: {'cp_1': card},
    );
    expect(find.text('Olá'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('componente inexistente desenha a caixa de erro com o id', (
    tester,
  ) async {
    await _pump(tester, _instance('cp_x'), components: {'cp_1': card});
    expect(find.textContaining('cp_x'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem busca de componentes cai na caixa de erro', (tester) async {
    await _pump(tester, _instance('cp_1', {'titulo': 'Olá'}));
    expect(find.text('Olá'), findsNothing);
    expect(find.textContaining('busca de componentes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arg obrigatório ausente vira caixa de erro', (tester) async {
    await _pump(tester, _instance('cp_1'), components: {'cp_1': card});
    expect(find.textContaining('titulo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ciclo vira caixa de erro, sem exceção', (tester) async {
    final loop = _component(
      'cp_loop',
      _instance('cp_loop', {'titulo': 'x'}),
    );
    await _pump(
      tester,
      _instance('cp_loop', {'titulo': 'x'}),
      components: {'cp_loop': loop},
    );
    expect(find.byType(Text), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
