import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/node_tag.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/selectable_node.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

Future<void> _pumpCanvas(
  WidgetTester tester,
  SduiNode node, {
  String? selectedNodeId,
  String? hoveredNodeId,
  void Function(String targetId, DragPayload payload)? onAccept,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SduiView(
          node: node,
          nodeWrapper: (each, built) => SelectableNode(
            node: each,
            built: built,
            isSelected: each.id == selectedNodeId,
            isHovered: each.id == hoveredNodeId,
            onSelect: () {},
            onHover: (_) {},
            onAccept: (payload) => onAccept?.call(each.id, payload),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('overlay de seleção do canvas', () {
    testWidgets('não embrulha o expanded, que precisa ser filho do flex', (
      tester,
    ) async {
      await _pumpCanvas(
        tester,
        const SduiNode(
          id: 'col',
          type: 'column',
          children: [
            SduiNode(
              id: 'exp',
              type: 'expanded',
              child: SduiNode(
                id: 'txt',
                type: 'text',
                properties: {'data': 'Oi'},
              ),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Oi'), findsOneWidget);
    });

    testWidgets('etiqueta do nó só aparece em seleção ou hover', (
      tester,
    ) async {
      const arvore = SduiNode(
        id: 'col',
        type: 'column',
        children: [
          SduiNode(
            id: 'ct',
            type: 'container',
            properties: {'height': 40.0},
            child: SduiNode(
              id: 'txt',
              type: 'text',
              properties: {'data': 'Oi'},
            ),
          ),
        ],
      );

      await _pumpCanvas(tester, arvore);
      expect(find.byType(NodeTag), findsNothing);

      await _pumpCanvas(tester, arvore, selectedNodeId: 'ct');
      expect(find.byType(NodeTag), findsOneWidget);

      await _pumpCanvas(tester, arvore, hoveredNodeId: 'txt');
      expect(find.byType(NodeTag), findsOneWidget);
    });

    testWidgets('preserva as constraints do pai (stretch continua esticando)', (
      tester,
    ) async {
      await _pumpCanvas(
        tester,
        const SduiNode(
          id: 'col',
          type: 'column',
          properties: {'crossAxisAlignment': 'stretch'},
          children: [
            SduiNode(
              id: 'ct',
              type: 'container',
              properties: {'height': 40.0, 'color': '#FF0000'},
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      final largura = tester.getSize(find.byType(Column)).width;
      final container = tester.getSize(
        find.descendant(
          of: find.byType(SelectableNode).last,
          matching: find.byType(Container),
        ),
      );
      expect(container.width, largura);
    });
  });

  group('regressão: column > container > text', () {
    testWidgets('os três aparecem no canvas', (tester) async {
      await _pumpCanvas(
        tester,
        const SduiNode(
          id: 'col',
          type: 'column',
          children: [
            SduiNode(
              id: 'ct',
              type: 'container',
              properties: {'height': 60.0},
              child: SduiNode(
                id: 'txt',
                type: 'text',
                properties: {'data': 'Dentro do container'},
              ),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Dentro do container'), findsOneWidget);
    });

    testWidgets('container recém-solto nasce com altura visível', (
      tester,
    ) async {
      final novo = defaultNode('container', id: 'ct');

      await _pumpCanvas(
        tester,
        SduiNode(id: 'col', type: 'column', children: [novo]),
      );

      expect(tester.takeException(), isNull);
      final altura = tester
          .getSize(
            find.descendant(
              of: find.byType(SelectableNode).last,
              matching: find.byType(Container),
            ),
          )
          .height;
      expect(altura, greaterThan(0));
    });

    testWidgets('binding numa prop numérica não derruba o canvas', (
      tester,
    ) async {
      await _pumpCanvas(
        tester,
        const SduiNode(
          id: 'col',
          type: 'column',
          children: [
            SduiNode(
              id: 'ct',
              type: 'container',
              properties: {'width': '{{produto.largura}}', 'height': 40.0},
              child: SduiNode(
                id: 'txt',
                type: 'text',
                properties: {
                  'data': 'Oi',
                  'fontSize': '{{tema.tamanho}}',
                  'maxLines': '{{tema.linhas}}',
                },
              ),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Oi'), findsOneWidget);
    });
  });

  group('arrastar no mock reorganiza a árvore', () {
    const arvore = SduiNode(
      id: 'col',
      type: 'column',
      children: [
        SduiNode(
          id: 'ct',
          type: 'container',
          properties: {'height': 60.0, 'color': '#FF0000'},
        ),
        SduiNode(id: 'txt', type: 'text', properties: {'data': 'Alvo'}),
      ],
    );

    testWidgets('todo nó desenhado é origem de arraste', (tester) async {
      await _pumpCanvas(tester, arvore);

      // column + container + text (spacer/expanded ficam de fora, ver doc).
      expect(find.byType(Draggable<DragPayload>), findsNWidgets(3));
    });

    testWidgets('soltar um nó sobre outro entrega o alvo e o payload', (
      tester,
    ) async {
      String? alvo;
      DragPayload? recebido;
      await _pumpCanvas(
        tester,
        arvore,
        onAccept: (targetId, payload) {
          alvo = targetId;
          recebido = payload;
        },
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Container).first),
      );
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('Alvo')));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(alvo, 'txt');
      expect(recebido, isA<NodeDragPayload>());
      expect((recebido! as NodeDragPayload).nodeId, 'ct');
    });

    testWidgets('um nó não aceita a si mesmo como destino', (tester) async {
      var chamou = false;
      await _pumpCanvas(
        tester,
        arvore,
        onAccept: (_, _) => chamou = true,
      );

      final centro = tester.getCenter(find.text('Alvo'));
      final gesture = await tester.startGesture(centro);
      await tester.pump();
      await gesture.moveTo(centro + const Offset(0, 4));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(chamou, isFalse);
    });
  });
}
