import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/prop_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({
  bool initiallyExpanded = true,
  ValueChanged<bool>? onExpandedChanged,
}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: PropSection(
      label: 'Aparência',
      summary: 'resumo',
      initiallyExpanded: initiallyExpanded,
      onExpandedChanged: onExpandedChanged,
      children: const [Text('campo')],
    ),
  ),
);

void main() {
  testWidgets('nasce expandida por padrão, mostrando os filhos', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    expect(find.text('campo'), findsOneWidget);
  });

  testWidgets('initiallyExpanded: false nasce fechada', (tester) async {
    await tester.pumpWidget(_harness(initiallyExpanded: false));

    expect(find.text('campo'), findsNothing);
  });

  testWidgets('tocar o cabeçalho alterna a visibilidade dos filhos', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.text('APARÊNCIA'));
    await tester.pumpAndSettle();

    expect(find.text('campo'), findsNothing);
  });

  testWidgets(
    'onExpandedChanged é chamado com o novo estado a cada alternância',
    (tester) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        _harness(onExpandedChanged: changes.add),
      );

      await tester.tap(find.text('APARÊNCIA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APARÊNCIA'));
      await tester.pumpAndSettle();

      expect(changes, [false, true]);
    },
  );

  testWidgets(
    'onExpandedChanged ausente não impede o toggle local',
    (tester) async {
      await tester.pumpWidget(_harness());

      await tester.tap(find.text('APARÊNCIA'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('campo'), findsNothing);
    },
  );
}
