import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

const SduiAction _pressAction = SduiAction(
  type: 'navigate',
  params: {'slug': 'promocoes'},
);

const SduiAction _longPressAction = SduiAction(
  type: 'copyToClipboard',
  params: {'text': 'cupom'},
);

const Map<String, Type> _variants = {
  'elevated': ElevatedButton,
  'text': TextButton,
  'outlined': OutlinedButton,
  'filled': FilledButton,
};

SduiNode _button(
  String variant, {
  bool enabled = true,
  bool withLongPress = true,
}) => SduiNode(
  id: 'btn',
  type: 'button',
  properties: {'label': 'Comprar', 'variant': variant, 'enabled': enabled},
  events: {
    'onPressed': [_pressAction.toJson()],
    if (withLongPress) 'onLongPress': [_longPressAction.toJson()],
  },
);

Future<List<SduiAction>> _pump(WidgetTester tester, SduiNode node) async {
  final received = <SduiAction>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SduiView(node: node, onAction: received.add),
        ),
      ),
    ),
  );
  return received;
}

ButtonStyleButton _material(WidgetTester tester, Type type) =>
    tester.widget<ButtonStyleButton>(find.byType(type));

void main() {
  for (final MapEntry(key: variant, value: type) in _variants.entries) {
    group('button $variant', () {
      testWidgets('toque entrega só o onPressed e toque longo só o '
          'onLongPress', (tester) async {
        final received = await _pump(tester, _button(variant));

        await tester.tap(find.byType(type));
        await tester.pump();
        expect(received, [_pressAction]);

        received.clear();
        await tester.longPress(find.byType(type));
        await tester.pump();
        expect(received, [_longPressAction]);
      });

      testWidgets('enabled: false fica desabilitado e não despacha', (
        tester,
      ) async {
        final received = await _pump(
          tester,
          _button(variant, enabled: false),
        );

        final button = _material(tester, type);
        expect(button.onPressed, isNull);
        expect(button.onLongPress, isNull);

        await tester.tap(find.byType(type), warnIfMissed: false);
        await tester.longPress(find.byType(type), warnIfMissed: false);
        await tester.pump();
        expect(received, isEmpty);
      });

      testWidgets('sem onLongPress, segurar continua entregando o onPressed', (
        tester,
      ) async {
        final received = await _pump(
          tester,
          _button(variant, withLongPress: false),
        );

        expect(_material(tester, type).onLongPress, isNull);

        await tester.longPress(find.byType(type));
        await tester.pump();
        expect(received, [_pressAction]);
      });
    });
  }
}
