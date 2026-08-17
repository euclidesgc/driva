import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector_header.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/wrap_node_button.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/remove_node_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  ValueChanged<String>? onWrap,
  VoidCallback? onRemove,
  String? removeLabel,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: InspectorHeader(
          title: 'Text',
          subtitle: 'id nd_1',
          iconType: 'text',
          onRemove: onRemove,
          removeLabel: removeLabel,
          onWrap: onWrap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('sem onWrap (o Inspector é da página) não há botão de envolver', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(WrapNodeButton), findsNothing);
  });

  testWidgets('com nó selecionado, envolver aparece ao lado de remover', (
    tester,
  ) async {
    await _pump(
      tester,
      onWrap: (_) {},
      onRemove: () {},
      removeLabel: removeNodeLabel,
    );

    expect(find.byType(WrapNodeButton), findsOneWidget);
    expect(find.byTooltip(removeNodeLabel), findsOneWidget);
  });

  testWidgets('o botão de envolver repassa o tipo escolhido', (tester) async {
    String? escolhido;
    await _pump(tester, onWrap: (type) => escolhido = type);

    await tester.tap(find.byType(WrapNodeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Column'));
    await tester.pumpAndSettle();

    expect(escolhido, 'column');
  });

  testWidgets('na raiz, o tooltip do remover avisa que esvazia o conteúdo', (
    tester,
  ) async {
    await _pump(
      tester,
      onWrap: (_) {},
      onRemove: () {},
      removeLabel: clearContentLabel,
    );

    expect(find.byTooltip(clearContentLabel), findsOneWidget);
    expect(find.byTooltip(removeNodeLabel), findsNothing);
  });
}
