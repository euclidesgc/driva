import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/theme_color_list.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _cor = PropField(
  key: 'color',
  kind: FieldKind.color,
  label: 'Cor',
  group: FieldGroups.style,
);

Future<List<Object?>> _pumpEditor(
  WidgetTester tester, {
  Object? value,
}) async {
  final changes = <Object?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: PropFieldEditor(
            onBind: (_) {},
            onUnbind: () {},
            field: _cor,
            value: value,
            onChanged: changes.add,
          ),
        ),
      ),
    ),
  );
  return changes;
}

void main() {
  alphaAndThemeTests();
  group('campo hex', () {
    testWidgets('digitar hex válido emite a cor', (tester) async {
      final changes = await _pumpEditor(tester);

      await tester.enterText(find.byType(TextField).first, '#2F6BFF');
      await tester.pump();

      expect(changes, ['#2F6BFF']);
    });

    testWidgets('digitar hex inválido não emite nada', (tester) async {
      final changes = await _pumpEditor(tester);

      await tester.enterText(find.byType(TextField).first, '#ZZZZZZ');
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('minúsculo vira maiúsculo ao digitar', (tester) async {
      await _pumpEditor(tester);

      await tester.enterText(find.byType(TextField).first, '#2f6bff');
      await tester.pump();

      expect(find.text('#2F6BFF'), findsOneWidget);
    });
  });

  group('botão limpar', () {
    testWidgets('some quando não há cor', (tester) async {
      await _pumpEditor(tester);

      expect(find.byTooltip('Limpar cor'), findsNothing);
    });

    testWidgets('aparece com cor definida e emite null ao tocar', (
      tester,
    ) async {
      final changes = await _pumpEditor(tester, value: '#2F6BFF');

      expect(find.byTooltip('Limpar cor'), findsOneWidget);
      await tester.tap(find.byTooltip('Limpar cor'));
      await tester.pump();

      expect(changes, [null]);
    });
  });

  group('swatches rápidos', () {
    testWidgets('tocar um swatch emite o hex dele', (tester) async {
      final changes = await _pumpEditor(tester);

      await tester.tap(find.byTooltip('#16A34A'));
      await tester.pump();

      expect(changes, ['#16A34A']);
    });
  });

  group('seletor completo', () {
    testWidgets('abre pelo swatch de preview e escolher uma cor emite o hex', (
      tester,
    ) async {
      final changes = await _pumpEditor(tester, value: '#2F6BFF');

      await tester.tap(find.byTooltip('Abrir seletor de cores'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(ColorPicker),
          matching: find.byType(TextField),
        ),
        '16A34A',
      );
      await tester.pump();
      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();

      expect(changes, ['#16A34A']);
    });

    testWidgets('cancelar não emite mudança', (tester) async {
      final changes = await _pumpEditor(tester, value: '#2F6BFF');

      await tester.tap(find.byTooltip('Abrir seletor de cores'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
    });

    testWidgets('cancelar sem cor prévia não define branco', (tester) async {
      final changes = await _pumpEditor(tester);

      await tester.tap(find.byTooltip('Abrir seletor de cores'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
    });

    testWidgets('sem cor prévia, escolher branco e confirmar emite branco', (
      tester,
    ) async {
      final changes = await _pumpEditor(tester);

      await tester.tap(find.byTooltip('Abrir seletor de cores'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();

      expect(changes, ['#FFFFFF']);
    });
  });
}

void alphaAndThemeTests() {
  group('alfa e cores do tema', () {
    testWidgets('#80FF0000 emite a cor com alfa 0x80', (tester) async {
      final changes = await _pumpEditor(tester);
      await tester.enterText(find.byType(TextField).first, '#80FF0000');
      await tester.pump();
      expect(changes, ['#80FF0000']);
    });

    testWidgets('escolher primary grava a referência ao papel', (tester) async {
      final changes = await _pumpEditor(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('abrir seletor')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('theme-color-primary')));
      await tester.pumpAndSettle();
      expect(changes, [
        {r'$theme': 'primary'},
      ]);
    });

    testWidgets('golden do popover aberto com as duas áreas', (tester) async {
      await _pumpEditor(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('abrir seletor')).first);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AlertDialog),
        matchesGoldenFile('goldens/color_picker_popover.png'),
      );
    });

    testWidgets('busca "text" deixa só papéis com text no nome', (
      tester,
    ) async {
      await _pumpEditor(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('abrir seletor')).first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(ThemeColorList),
          matching: find.byType(TextField),
        ),
        'text',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('theme-color-primaryText')), findsOne);
      expect(find.byKey(const ValueKey('theme-color-secondaryText')), findsOne);
      expect(find.byKey(const ValueKey('theme-color-primary')), findsNothing);
    });
  });
}
