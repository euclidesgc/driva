import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/input/search_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/actions/action_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

class _Opened {
  Future<ActionDescriptor?>? result;
}

Future<_Opened> _open(
  WidgetTester tester, {
  List<ActionDescriptor>? actions,
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final opened = _Opened();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => opened.result = ActionPickerDialog.show(
              context,
              actions: actions,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return opened;
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(SearchField),
      matching: find.byType(TextField),
    ),
    text,
  );
  await tester.pumpAndSettle();
}

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  group('ActionPickerDialog', () {
    testWidgets('sem busca agrupa por categoria na ordem do seletor', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Escolher ação'), findsOneWidget);
      final tops = [
        for (final title in ['Navegação', 'Alertas', 'Utilitários', 'Backend'])
          _top(tester, title),
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(_top(tester, 'Mostrar aviso'), greaterThan(tops[1]));
      expect(_top(tester, 'Mostrar aviso'), lessThan(tops[2]));
    });

    testWidgets('a busca por rótulo mostra o breadcrumb', (tester) async {
      await _open(tester);

      await _search(tester, 'aviso');

      expect(find.text('Mostrar aviso'), findsOneWidget);
      expect(find.text('Alertas > Mostrar aviso'), findsOneWidget);
      expect(find.text('Voltar'), findsNothing);
    });

    testWidgets('a busca acha pelo type sem diferenciar maiúsculas', (
      tester,
    ) async {
      await _open(tester);

      await _search(tester, 'SNACK');

      expect(find.text('Mostrar aviso'), findsOneWidget);
    });

    testWidgets('sem resultado avisa', (tester) async {
      await _open(tester);

      await _search(tester, 'xyz');

      expect(find.text('Nenhuma ação encontrada.'), findsOneWidget);
    });

    testWidgets('tocar numa ação devolve a ação', (tester) async {
      final opened = await _open(tester);

      await tester.tap(find.text('Mostrar aviso'));
      await tester.pumpAndSettle();

      expect((await opened.result)?.type, 'showSnackBar');
      expect(find.byType(ActionPickerDialog), findsNothing);
    });

    testWidgets('Esc fecha devolvendo null', (tester) async {
      final opened = await _open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(ActionPickerDialog), findsNothing);
      expect(await opened.result, isNull);
    });

    testWidgets('categoria sem ação não aparece', (tester) async {
      await _open(
        tester,
        actions: [
          for (final action in actionCatalog)
            if (action.category == ActionCategories.utilities) action,
        ],
      );

      expect(find.text('Utilitários'), findsOneWidget);
      expect(find.text('Navegação'), findsNothing);
      expect(find.text('Alertas'), findsNothing);
      expect(find.text('Backend'), findsNothing);
    });
  });
}
