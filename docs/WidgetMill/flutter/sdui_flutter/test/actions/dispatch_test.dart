import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

void main() {
  testWidgets('tap em gestureDetector dispara as ações na ordem', (tester) async {
    final fired = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SduiView.fromJson(
            {
              'type': 'gestureDetector',
              'events': {
                'onTap': [
                  {
                    'type': 'navigate',
                    'params': {'routeId': 'r'},
                  },
                  {
                    'type': 'track',
                    'params': {'event': 'x'},
                  },
                ],
              },
              'child': {
                'type': 'text',
                'props': {'data': 'toque'},
              },
            },
            onAction: (a) => fired.add(a.type),
          ),
        ),
      ),
    );

    await tester.tap(find.text('toque'));
    expect(fired, ['navigate', 'track']);
  });

  testWidgets('button onPressed dispara a ação com params', (tester) async {
    final captured = <SduiAction>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SduiView.fromJson(
            {
              'type': 'button',
              'props': {
                'label': 'OK',
                'onPressed': [
                  {
                    'type': 'track',
                    'params': {'event': 'click'},
                  },
                ],
              },
            },
            onAction: captured.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('OK'));
    expect(captured.single.type, 'track');
    expect(captured.single.params['event'], 'click');
  });
}
