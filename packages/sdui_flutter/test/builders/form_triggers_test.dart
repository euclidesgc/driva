import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

const SduiAction _changedAction = SduiAction(
  type: 'showSnackBar',
  params: {'message': 'mudou'},
);

const SduiAction _submitAction = SduiAction(
  type: 'navigate',
  params: {'slug': 'busca'},
);

Map<String, dynamic> _onChanged() => {
  'onChanged': [_changedAction.toJson()],
};

Future<List<SduiAction>> _pump(WidgetTester tester, SduiNode node) async {
  final received = <SduiAction>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SduiView(node: node, onAction: received.add),
        ),
      ),
    ),
  );
  return received;
}

SduiNode _control(String type, {Map<String, dynamic> events = const {}}) {
  final properties = switch (type) {
    'switch' => const {'value': false},
    'checkbox' => const {'value': false},
    'radio' => const {'selected': false},
    'slider' => const {'value': 50, 'min': 0, 'max': 100},
    _ => throw ArgumentError(type),
  };
  return SduiNode(
    id: type,
    type: type,
    properties: properties,
    events: events,
  );
}

const Map<String, Type> _tappableControls = {
  'switch': Switch,
  'checkbox': Checkbox,
  'radio': Radio<bool>,
};

void main() {
  for (final MapEntry(key: type, value: widgetType)
      in _tappableControls.entries) {
    testWidgets('$type com onChanged: um toque entrega a ação configurada', (
      tester,
    ) async {
      final received = await _pump(
        tester,
        _control(type, events: _onChanged()),
      );

      await tester.tap(find.byType(widgetType));
      await tester.pump();

      expect(received, [_changedAction]);
    });

    testWidgets('$type sem onChanged não chama onAction', (tester) async {
      final received = await _pump(tester, _control(type));

      await tester.tap(find.byType(widgetType));
      await tester.pump();

      expect(received, isEmpty);
    });
  }

  testWidgets('switch mostra o mesmo valor antes e depois do toque', (
    tester,
  ) async {
    await _pump(tester, _control('switch', events: _onChanged()));
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  group('dropdown', () {
    SduiNode dropdown({Map<String, dynamic> events = const {}}) => SduiNode(
      id: 'dd',
      type: 'dropdown',
      properties: const {'value': 'Pix'},
      events: events,
    );

    Future<void> pickItem(WidgetTester tester) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pix').last);
      await tester.pumpAndSettle();
    }

    testWidgets('escolher o item no menu aberto entrega a ação', (
      tester,
    ) async {
      final received = await _pump(tester, dropdown(events: _onChanged()));

      await pickItem(tester);

      expect(received, [_changedAction]);
    });

    testWidgets('sem onChanged não chama onAction', (tester) async {
      final received = await _pump(tester, dropdown());

      await pickItem(tester);

      expect(received, isEmpty);
    });
  });

  group('textField', () {
    SduiNode textField({Map<String, dynamic> events = const {}}) => SduiNode(
      id: 'tf',
      type: 'textField',
      properties: const {'label': 'Busca'},
      events: events,
    );

    testWidgets('digitar entrega a ação do onChanged', (tester) async {
      final received = await _pump(tester, textField(events: _onChanged()));

      await tester.enterText(find.byType(TextFormField), 'a');
      await tester.pump();

      expect(received, [_changedAction]);
    });

    testWidgets('enviar pelo teclado entrega a ação do onSubmit', (
      tester,
    ) async {
      final received = await _pump(
        tester,
        textField(
          events: {
            'onSubmit': [_submitAction.toJson()],
          },
        ),
      );

      await tester.showKeyboard(find.byType(TextFormField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(received, [_submitAction]);
    });

    testWidgets('sem events, digitar não chama onAction', (tester) async {
      final received = await _pump(tester, textField());

      await tester.enterText(find.byType(TextFormField), 'a');
      await tester.pump();

      expect(received, isEmpty);
    });
  });

  group('slider', () {
    testWidgets('um arrasto entrega exatamente uma ação', (tester) async {
      final received = await _pump(
        tester,
        _control('slider', events: _onChanged()),
      );

      await tester.drag(find.byType(Slider), const Offset(120, 0));
      await tester.pump();

      expect(received, [_changedAction]);
    });

    testWidgets('sem onChanged, arrastar não chama onAction', (tester) async {
      final received = await _pump(tester, _control('slider'));

      await tester.drag(find.byType(Slider), const Offset(120, 0));
      await tester.pump();

      expect(received, isEmpty);
    });
  });
}
