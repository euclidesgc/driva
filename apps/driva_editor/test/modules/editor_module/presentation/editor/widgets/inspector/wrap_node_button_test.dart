import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/wrap_node_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/wrap_node_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {ValueChanged<String>? onWrap}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: WrapNodeButton(onWrap: onWrap ?? (_) {})),
    ),
  );
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.select_all));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('o gatilho é um ícone com tooltip que explica a ação', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byIcon(Icons.select_all), findsOneWidget);
    expect(find.byTooltip('Envolver em Column ou Row'), findsOneWidget);
  });

  testWidgets('o menu oferece Column e Row, com o atalho só na Column', (
    tester,
  ) async {
    await _pump(tester);
    await _openMenu(tester);

    expect(find.byType(WrapNodeMenuItem), findsNWidgets(2));
    expect(find.text('Column'), findsOneWidget);
    expect(find.text('Row'), findsOneWidget);
    expect(find.text('Ctrl+G'), findsOneWidget);
  });

  testWidgets('cada item do menu tem ícone e rótulo — cor não é o sinal', (
    tester,
  ) async {
    await _pump(tester);
    await _openMenu(tester);

    for (final item in tester.widgetList<WrapNodeMenuItem>(
      find.byType(WrapNodeMenuItem),
    )) {
      expect(item.wrapperType, isNotEmpty);
    }
    expect(
      find.descendant(
        of: find.byType(WrapNodeMenuItem).first,
        matching: find.byType(Icon),
      ),
      findsOneWidget,
    );
  });

  testWidgets('escolher Column devolve o tipo column', (tester) async {
    String? escolhido;
    await _pump(tester, onWrap: (type) => escolhido = type);
    await _openMenu(tester);

    await tester.tap(find.text('Column'));
    await tester.pumpAndSettle();

    expect(escolhido, 'column');
  });

  testWidgets('escolher Row devolve o tipo row', (tester) async {
    String? escolhido;
    await _pump(tester, onWrap: (type) => escolhido = type);
    await _openMenu(tester);

    await tester.tap(find.text('Row'));
    await tester.pumpAndSettle();

    expect(escolhido, 'row');
  });

  testWidgets('abrir o menu sozinho não dispara o callback', (tester) async {
    var chamou = false;
    await _pump(tester, onWrap: (_) => chamou = true);
    await _openMenu(tester);

    expect(chamou, isFalse);
  });
}
