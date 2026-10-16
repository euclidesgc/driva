import 'dart:ui' show Tristate;

import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _padding = PropField(
  key: 'padding',
  kind: FieldKind.edgeInsets,
  label: 'Espaçamento',
  group: FieldGroups.layout,
);

const ValueKey<String> _childKey = ValueKey('conteudo-completo');

Future<void> _pump(
  WidgetTester tester, {
  Object? value = const {'all': 8},
  bool initiallyExpanded = false,
  double width = 360,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: CollapsiblePropEditor(
          field: _padding,
          value: value,
          initiallyExpanded: initiallyExpanded,
          child: const SizedBox(key: _childKey, height: 40),
        ),
      ),
    ),
  ),
);

Finder _row() => find.byType(PropSummaryRow);

Finder _labelled() => find.bySemanticsLabel(RegExp('Espaçamento'));

Future<void> _focusRow(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

void main() {
  group('CollapsiblePropEditor', () {
    testWidgets('recolhido mostra o resumo numa linha e esconde o child', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Espaçamento'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.byKey(_childKey), findsNothing);
      expect(
        tester.getSize(_row()).height,
        lessThanOrEqualTo(AppSizes.propSummaryRowHeight),
      );
    });

    testWidgets('rótulo longo é cortado na linha, sem estourar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: PropSummaryRow(
                label: 'Espaçamento interno de todos os lados do cartão',
                summary: '8',
                isExpanded: false,
                onToggle: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(_row()).height,
        lessThanOrEqualTo(AppSizes.propSummaryRowHeight),
      );
    });

    testWidgets('resumo longo continua em uma linha, sem estourar', (
      tester,
    ) async {
      await _pump(
        tester,
        value: 'texto muito longo ' * 20,
        width: 220,
      );

      final summary = tester.widget<Text>(
        find.textContaining('texto muito longo'),
      );
      expect(summary.maxLines, 1);
      expect(summary.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(_row()).height,
        lessThanOrEqualTo(AppSizes.propSummaryRowHeight),
      );
    });

    testWidgets('tocar mostra o child e tocar de novo recolhe', (tester) async {
      await _pump(tester);

      await tester.tap(_row());
      await tester.pump();
      expect(find.byKey(_childKey), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      await tester.tap(_row());
      await tester.pump();
      expect(find.byKey(_childKey), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('initiallyExpanded abre com o child visível', (tester) async {
      await _pump(tester, initiallyExpanded: true);

      expect(find.byKey(_childKey), findsOneWidget);
    });

    testWidgets('Semantics expõe o rótulo, botão e expanded', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      var flags = tester.getSemantics(_labelled()).flagsCollection;
      expect(flags.isButton, isTrue);
      expect(flags.isExpanded, Tristate.isFalse);

      await tester.tap(_row());
      await tester.pump();

      flags = tester.getSemantics(_labelled()).flagsCollection;
      expect(flags.isExpanded, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('Enter alterna', (tester) async {
      await _pump(tester);
      await _focusRow(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(_childKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(_childKey), findsNothing);
    });

    testWidgets('Espaço alterna', (tester) async {
      await _pump(tester);
      await _focusRow(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.byKey(_childKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.byKey(_childKey), findsNothing);
    });
  });
}
