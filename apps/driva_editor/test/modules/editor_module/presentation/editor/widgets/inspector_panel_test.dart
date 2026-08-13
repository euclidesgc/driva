import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

Future<void> _pump(
  WidgetTester tester, {
  SduiNode? node,
  Map<String, dynamic> safeArea = const {},
  ValueChanged<Map<String, dynamic>>? onUpdateSafeAreaProps,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 340,
          height: 700,
          child: InspectorPanel(
            node: node,
            safeArea: safeArea,
            contentName: 'Home',
            contentSlug: 'home',
            onUpdateProps: (_, _) {},
            onUpdateSafeAreaProps: onUpdateSafeAreaProps ?? (_) {},
            onRemove: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('sem nó selecionado, o Inspector é da página', () {
    testWidgets('cabeçalho identifica a página, não a raiz do conteúdo', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Página'), findsOneWidget);
      expect(find.text('Home · slug home'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('mostra as props da área segura', (tester) async {
      await _pump(tester);

      expect(find.text('Usar área segura'), findsOneWidget);
      expect(find.text('Respeitar o topo'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Espaçamento mínimo'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Espaçamento mínimo'), findsOneWidget);
    });

    testWidgets('editar uma prop chama o callback da página', (tester) async {
      Map<String, dynamic>? patch;
      await _pump(tester, onUpdateSafeAreaProps: (value) => patch = value);

      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      expect(patch, {'enabled': false});
    });
  });

  group('com nó selecionado, o Inspector é do nó', () {
    testWidgets('cabeçalho traz o rótulo do widget e a ação de remover', (
      tester,
    ) async {
      await _pump(
        tester,
        node: const SduiNode(id: 'nd_1', type: 'text'),
      );

      expect(find.text('Text'), findsOneWidget);
      expect(find.text('id nd_1'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.text('Usar área segura'), findsNothing);
    });

    testWidgets('folha sem props editáveis avisa em vez de listar vazio', (
      tester,
    ) async {
      await _pump(
        tester,
        node: const SduiNode(id: 'nd_1', type: 'spacer'),
      );

      final descriptor = descriptorFor('spacer')!;
      expect(
        descriptor.fields.isEmpty
            ? find.text('Sem propriedades editáveis.')
            : find.byType(InspectorPropList),
        findsOneWidget,
      );
    });
  });
}
