import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';
import 'package:sdui_flutter/src/layout/sdui_dimension_box.dart';
import 'package:sdui_flutter/src/parsing/parsers.dart';

const _marker = Key('alvo');

/// Constraints **frouxas**, como as que Column/Row/Stack realmente entregam.
/// Um pai tight forçaria o tamanho de volta no `enforce`, que é o contrato do
/// próprio `Container` — e não o que se quer medir aqui.
Future<void> _pumpBox(
  WidgetTester tester,
  SduiDimensionBox box, {
  Size pai = const Size(500, 400),
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(pai),
          child: box,
        ),
      ),
    ),
  );
}

Future<void> _pumpNode(WidgetTester tester, SduiNode node) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SduiView(node: node)),
    ),
  );
}

void main() {
  group('resolveDimension', () {
    test('pixels passam direto', () {
      expect(resolveDimension(100, 500), 100);
    });

    test('porcentagem é fração do disponível', () {
      expect(resolveDimension('70%', 500), 350);
      expect(resolveDimension('100%', 500), 500);
    });

    test('preencher usa todo o disponível', () {
      expect(resolveDimension('inf', 500), 500);
    });

    test('eixo não-limitado devolve null em vez de estourar', () {
      expect(resolveDimension('70%', double.infinity), isNull);
      expect(resolveDimension('inf', double.infinity), isNull);
    });

    test('pixels valem mesmo em eixo não-limitado', () {
      expect(resolveDimension(100, double.infinity), 100);
    });

    test('valor não reconhecido devolve null', () {
      expect(resolveDimension(null, 500), isNull);
      expect(resolveDimension('{{x}}', 500), isNull);
    });
  });

  group('SduiDimensionBox', () {
    testWidgets('sem nenhuma dimensão, devolve o filho sem envolver nada', (
      tester,
    ) async {
      await _pumpBox(
        tester,
        const SduiDimensionBox(child: SizedBox(key: _marker)),
      );

      expect(
        find.descendant(
          of: find.byType(SduiDimensionBox),
          matching: find.byType(LayoutBuilder),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(SduiDimensionBox),
          matching: find.byType(ConstrainedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('resolve porcentagem contra o pai nos dois eixos', (
      tester,
    ) async {
      await _pumpBox(
        tester,
        const SduiDimensionBox(
          width: '50%',
          height: '25%',
          child: SizedBox.expand(key: _marker),
        ),
      );

      expect(tester.getSize(find.byKey(_marker)), const Size(250, 100));
    });

    testWidgets('mistura pixels num eixo e porcentagem no outro', (
      tester,
    ) async {
      await _pumpBox(
        tester,
        const SduiDimensionBox(
          width: 120,
          height: '50%',
          child: SizedBox.expand(key: _marker),
        ),
      );

      expect(tester.getSize(find.byKey(_marker)), const Size(120, 200));
    });

    testWidgets('maxWidth limita o "preencher"', (tester) async {
      await _pumpBox(
        tester,
        const SduiDimensionBox(
          width: 'inf',
          maxWidth: 200,
          height: 40,
          child: SizedBox.expand(key: _marker),
        ),
      );

      expect(tester.getSize(find.byKey(_marker)).width, 200);
    });

    testWidgets('minWidth eleva o tamanho de um filho pequeno', (tester) async {
      await _pumpBox(
        tester,
        const SduiDimensionBox(
          minWidth: 180,
          height: 40,
          child: SizedBox(key: _marker),
        ),
      );

      expect(tester.getSize(find.byKey(_marker)).width, 180);
    });
  });

  group('container no renderer', () {
    testWidgets('altura "inf" dentro de Column não estoura o RenderFlex', (
      tester,
    ) async {
      await _pumpNode(
        tester,
        const SduiNode(
          id: 'col',
          type: 'column',
          children: [
            SduiNode(
              id: 'ct',
              type: 'container',
              properties: {'width': 'inf', 'height': 'inf'},
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('altura em porcentagem dentro de Column não estoura', (
      tester,
    ) async {
      await _pumpNode(
        tester,
        const SduiNode(
          id: 'col',
          type: 'column',
          children: [
            SduiNode(
              id: 'ct',
              type: 'container',
              properties: {'height': '50%'},
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('margem fica fora das constraints, como no Container', (
      tester,
    ) async {
      await _pumpNode(
        tester,
        const SduiNode(
          id: 'ct',
          type: 'container',
          properties: {
            'width': 100.0,
            'height': 40.0,
            'margin': {'all': 8.0},
          },
        ),
      );

      final total = tester.getSize(find.byType(Padding).first);
      expect(total.width, 116);
      expect(total.height, 56);
    });
  });
}
