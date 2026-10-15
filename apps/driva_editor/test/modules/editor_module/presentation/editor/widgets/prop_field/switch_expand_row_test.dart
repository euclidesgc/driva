import 'dart:ui' show Tristate;

import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const ValueKey<String> _childKey = ValueKey('conteudo-do-switch');

class _Harness extends StatefulWidget {
  const _Harness({required this.props, required this.changes});

  final Map<String, Object?> props;
  final List<bool> changes;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SwitchExpandRow(
        label: 'Sombra',
        value: widget.props['shadowEnabled'] == true,
        onChanged: (enabled) {
          widget.changes.add(enabled);
          setState(() => widget.props['shadowEnabled'] = enabled);
        },
        child: const SizedBox(key: _childKey, height: 40),
      ),
    ),
  );
}

Future<List<bool>> _pump(
  WidgetTester tester, {
  Map<String, Object?>? props,
}) async {
  final changes = <bool>[];
  await tester.pumpWidget(
    _Harness(
      props: props ?? <String, Object?>{'shadowEnabled': false},
      changes: changes,
    ),
  );
  return changes;
}

void main() {
  group('SwitchExpandRow', () {
    testWidgets('desligado, o child fica fora da árvore', (tester) async {
      await _pump(tester);

      expect(find.text('Sombra'), findsOneWidget);
      expect(find.byKey(_childKey), findsNothing);
    });

    testWidgets('ligar mostra o child e chama onChanged(true)', (tester) async {
      final changes = await _pump(tester);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(changes, [true]);
      expect(find.byKey(_childKey), findsOneWidget);
    });

    testWidgets('desligar esconde o child e chama onChanged(false)', (
      tester,
    ) async {
      final changes = await _pump(
        tester,
        props: <String, Object?>{'shadowEnabled': true},
      );
      expect(find.byKey(_childKey), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(changes, [false]);
      expect(find.byKey(_childKey), findsNothing);
    });

    testWidgets('as props do conteúdo sobrevivem a desligar e religar', (
      tester,
    ) async {
      final props = <String, Object?>{
        'shadowEnabled': true,
        'shadowBlur': 12,
        'shadowColor': '#000000',
      };
      await _pump(tester, props: props);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(props['shadowBlur'], 12);
      expect(props['shadowColor'], '#000000');

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(props, {
        'shadowEnabled': true,
        'shadowBlur': 12,
        'shadowColor': '#000000',
      });
      expect(find.byKey(_childKey), findsOneWidget);
    });

    testWidgets('Semantics expõe o rótulo e toggled', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      final off = tester.getSemantics(find.byType(Switch));
      expect(off.label, contains('Sombra'));
      expect(off.flagsCollection.isToggled, Tristate.isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      final on = tester.getSemantics(find.byType(Switch));
      expect(on.flagsCollection.isToggled, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('Espaço alterna', (tester) async {
      final changes = await _pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(changes, [true]);
      expect(find.byKey(_childKey), findsOneWidget);
    });
  });
}
