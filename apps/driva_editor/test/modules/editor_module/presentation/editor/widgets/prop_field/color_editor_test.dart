import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
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

      await tester.enterText(find.byType(TextField).last, '16A34A');
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
  });
}
