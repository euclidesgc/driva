import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

// Rede de caracterização por golden do renderer (F1 do refactor): um golden por
// tipo do catálogo, renderizando um nó mínimo daquele tipo. Congela a aparência
// atual de cada builder antes de refatorá-los.
//
// O pacote `sdui_flutter` não embarca fontes, então os textos saem na fonte de
// teste (glifos-caixa) — determinístico e estável. O comparador tolerante (5%)
// absorve ruído subpixel sem mascarar regressão estrutural.

/// Nó mínimo e representativo de cada [type] do catálogo. Tipos de slot único
/// ou múltiplo ganham filho(s) para renderizar algo visível; `spacer` é
/// embrulhado numa `row` (precisa de um pai Flex para não estourar).
SduiNode nodeFor(String type) => switch (type) {
  'text' => const SduiNode(
    id: 'n',
    type: 'text',
    properties: {'data': 'Texto', 'fontSize': 18.0},
  ),
  'container' => const SduiNode(
    id: 'n',
    type: 'container',
    properties: {
      'color': '#DDE3EA',
      'padding': {'all': 12.0},
      'borderRadius': 8.0,
    },
    child: SduiNode(id: 'c', type: 'text', properties: {'data': 'Box'}),
  ),
  'column' => const SduiNode(
    id: 'n',
    type: 'column',
    properties: {'spacing': 4.0},
    children: [
      SduiNode(id: 'a', type: 'text', properties: {'data': 'Um'}),
      SduiNode(id: 'b', type: 'text', properties: {'data': 'Dois'}),
    ],
  ),
  'row' => const SduiNode(
    id: 'n',
    type: 'row',
    properties: {'spacing': 8.0, 'mainAxisSize': 'min'},
    children: [
      SduiNode(id: 'a', type: 'text', properties: {'data': 'Um'}),
      SduiNode(id: 'b', type: 'text', properties: {'data': 'Dois'}),
    ],
  ),
  'stack' => const SduiNode(
    id: 'n',
    type: 'stack',
    children: [
      SduiNode(
        id: 'a',
        type: 'container',
        properties: {'color': '#DDE3EA', 'width': 90.0, 'height': 60.0},
      ),
      SduiNode(id: 'b', type: 'text', properties: {'data': 'Topo'}),
    ],
  ),
  'image' => const SduiNode(id: 'n', type: 'image'),
  'icon' => const SduiNode(
    id: 'n',
    type: 'icon',
    properties: {'icon': 'star', 'size': 40.0},
  ),
  'button' => const SduiNode(
    id: 'n',
    type: 'button',
    properties: {'label': 'Botão'},
  ),
  'textField' => const SduiNode(
    id: 'n',
    type: 'textField',
    properties: {'label': 'Nome', 'value': 'Ana'},
  ),
  'switch' => const SduiNode(
    id: 'n',
    type: 'switch',
    properties: {'value': true, 'label': 'Ativo'},
  ),
  'checkbox' => const SduiNode(
    id: 'n',
    type: 'checkbox',
    properties: {'value': true, 'label': 'Concordo'},
  ),
  'card' => const SduiNode(
    id: 'n',
    type: 'card',
    properties: {
      'elevation': 2.0,
      'margin': {'all': 8.0},
    },
    child: SduiNode(
      id: 'c',
      type: 'padding',
      properties: {
        'padding': {'all': 16.0},
      },
      child: SduiNode(id: 't', type: 'text', properties: {'data': 'Cartão'}),
    ),
  ),
  'divider' => const SduiNode(
    id: 'n',
    type: 'divider',
    properties: {'thickness': 2.0},
  ),
  'sizedBox' => const SduiNode(
    id: 'n',
    type: 'sizedBox',
    properties: {'width': 90.0, 'height': 48.0},
    child: SduiNode(
      id: 'c',
      type: 'container',
      properties: {'color': '#DDE3EA'},
    ),
  ),
  'padding' => const SduiNode(
    id: 'n',
    type: 'padding',
    properties: {
      'padding': {'all': 16.0},
    },
    child: SduiNode(id: 'c', type: 'text', properties: {'data': 'Recuo'}),
  ),
  'center' => const SduiNode(
    id: 'n',
    type: 'center',
    child: SduiNode(id: 'c', type: 'text', properties: {'data': 'Centro'}),
  ),
  'spacer' => const SduiNode(
    id: 'n',
    type: 'row',
    children: [
      SduiNode(id: 'a', type: 'text', properties: {'data': 'A'}),
      SduiNode(id: 's', type: 'spacer'),
      SduiNode(id: 'b', type: 'text', properties: {'data': 'B'}),
    ],
  ),
  _ => SduiNode(id: 'n', type: type),
};

Widget host(SduiNode node) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SduiView(node: node),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    final previous = goldenFileComparator;
    if (previous is LocalFileComparator && previous is! _TolerantComparator) {
      goldenFileComparator = _TolerantComparator(
        previous.basedir,
        threshold: 0.05,
      );
    }
  });

  for (final type in widgetCatalog.keys) {
    testWidgets('golden: nó $type', (tester) async {
      tester.view.physicalSize = const Size(320, 240);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(nodeFor(type)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(SduiView),
        matchesGoldenFile('goldens/node_$type.png'),
      );
    });
  }
}

/// Comparador de golden que aceita uma diferença até [threshold] (0..1) — o
/// suficiente para absorver o ruído subpixel sem mascarar regressões visuais
/// reais.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(Uri baseDir, {required this.threshold})
    : super(baseDir.resolve('placeholder_test.dart'));

  final double threshold;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) return true;
    if (result.diffPercent <= threshold) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
