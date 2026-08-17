import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/remove_node_labels.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_diagnostic_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _node = SduiNode(id: 'nd_1', type: 'spacer');

const _erro = SpecDiagnostic(
  nodeId: 'nd_1',
  nodeType: 'spacer',
  code: DiagnosticCode.flexOnlyOutsideFlex,
  severity: DiagnosticSeverity.error,
  message: 'Spacer só funciona dentro de uma Row ou Column.',
);

const _aviso = SpecDiagnostic(
  nodeId: 'nd_1',
  nodeType: 'padding',
  code: DiagnosticCode.emptySingleSlot,
  severity: DiagnosticSeverity.warning,
  message: 'Padding está sem filho e não desenha nada.',
);

Future<void> _pump(
  WidgetTester tester, {
  SduiNode node = _node,
  bool isRoot = false,
  bool isSelected = true,
  List<SpecDiagnostic> diagnostics = const [],
  VoidCallback? onRemove,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: TreeRow(
          node: node,
          depth: 0,
          isRoot: isRoot,
          isSelected: isSelected,
          diagnostics: diagnostics,
          onSelect: () {},
          onRemove: onRemove ?? () {},
          onAccept: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('marcação de problema na linha', () {
    testWidgets('nó sem diagnóstico não mostra ícone', (tester) async {
      await _pump(tester);

      expect(find.byType(TreeRowDiagnosticIcon), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
    });

    testWidgets('nó com erro mostra o ícone de erro', (tester) async {
      await _pump(tester, diagnostics: const [_erro]);

      expect(find.byType(TreeRowDiagnosticIcon), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('nó com aviso mostra o ícone de aviso', (tester) async {
      await _pump(tester, diagnostics: const [_aviso]);

      expect(find.byType(TreeRowDiagnosticIcon), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('a marcação não depende da linha estar selecionada', (
      tester,
    ) async {
      await _pump(tester, isSelected: false, diagnostics: const [_erro]);

      expect(find.byType(TreeRowDiagnosticIcon), findsOneWidget);
    });
  });

  group('excluir a raiz apaga a página inteira (F6)', () {
    testWidgets('na raiz, o remover diz que esvazia o conteúdo', (
      tester,
    ) async {
      await _pump(tester, isRoot: true);

      expect(find.byTooltip(clearContentLabel), findsOneWidget);
      expect(find.byTooltip(removeNodeLabel), findsNothing);
    });

    testWidgets('nos demais nós, o remover continua removendo o bloco', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byTooltip(removeNodeLabel), findsOneWidget);
      expect(find.byTooltip(clearContentLabel), findsNothing);
    });

    testWidgets('a raiz se identifica como o conteúdo no rótulo', (
      tester,
    ) async {
      await _pump(
        tester,
        node: const SduiNode(id: 'nd_root', type: 'column'),
        isRoot: true,
      );

      expect(find.text('Conteúdo (Column)'), findsOneWidget);
    });

    testWidgets('linha não selecionada não oferece o remover', (tester) async {
      await _pump(tester, isSelected: false);

      expect(find.byTooltip(removeNodeLabel), findsNothing);
    });

    testWidgets('tocar no remover chama o callback', (tester) async {
      var chamou = false;
      await _pump(tester, isRoot: true, onRemove: () => chamou = true);

      await tester.tap(find.byTooltip(clearContentLabel));
      await tester.pump();

      expect(chamou, isTrue);
    });
  });
}
