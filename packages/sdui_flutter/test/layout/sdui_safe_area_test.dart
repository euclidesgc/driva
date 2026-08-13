import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

const _padding = EdgeInsets.fromLTRB(10, 40, 10, 30);

ContentSpec _spec({Map<String, dynamic> safeArea = const {}}) => ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct',
  name: 'N',
  slug: 'n',
  safeArea: safeArea,
  root: const SduiNode(
    id: 'txt',
    type: 'text',
    properties: {'data': 'Conteúdo'},
  ),
);

Future<void> _pump(WidgetTester tester, ContentSpec spec) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(padding: _padding, viewPadding: _padding),
        child: Scaffold(body: SduiView.content(spec)),
      ),
    ),
  );
}

Rect _textRect(WidgetTester tester) =>
    tester.getRect(find.text('Conteúdo'));

void main() {
  testWidgets('sem props, respeita o recuo do dispositivo nos quatro lados', (
    tester,
  ) async {
    await _pump(tester, _spec());

    expect(_textRect(tester).top, greaterThanOrEqualTo(_padding.top));
  });

  testWidgets('enabled false devolve o conteúdo cru, colado no topo', (
    tester,
  ) async {
    await _pump(tester, _spec(safeArea: const {'enabled': false}));

    expect(find.byType(SafeArea), findsNothing);
    expect(_textRect(tester).top, lessThan(_padding.top));
  });

  testWidgets('desligar um lado só afeta aquele lado', (tester) async {
    await _pump(tester, _spec(safeArea: const {'top': false}));

    final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isTrue);
    expect(_textRect(tester).top, lessThan(_padding.top));
  });

  testWidgets('espaçamento mínimo entra mesmo onde não há recuo do sistema', (
    tester,
  ) async {
    await _pump(
      tester,
      _spec(
        safeArea: const {
          'top': false,
          'minimum': {'all': 24},
        },
      ),
    );

    expect(_textRect(tester).top, greaterThanOrEqualTo(24));
  });

  testWidgets('SduiView cru (fora de um conteúdo) não ganha área segura', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SduiView(
            node: SduiNode(
              id: 'txt',
              type: 'text',
              properties: {'data': 'Conteúdo'},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SduiSafeArea), findsNothing);
  });
}
