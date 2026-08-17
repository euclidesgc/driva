import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_diagnostic_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

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

final EditorColors _colors = AppTheme.light.extension<EditorColors>()!;

Future<void> _pump(
  WidgetTester tester,
  List<SpecDiagnostic> diagnostics,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: TreeRowDiagnosticIcon(diagnostics: diagnostics),
      ),
    ),
  );
}

Icon _icon(WidgetTester tester) => tester.widget<Icon>(find.byType(Icon));

void main() {
  testWidgets('erro: ícone, cor de perigo e rótulo semântico "Erro"', (
    tester,
  ) async {
    await _pump(tester, const [_erro]);

    final icon = _icon(tester);
    expect(icon.icon, Icons.error_outline);
    expect(icon.color, _colors.danger);
    expect(icon.semanticLabel, 'Erro');
  });

  testWidgets('aviso: ícone, cor de atenção e rótulo semântico "Aviso"', (
    tester,
  ) async {
    await _pump(tester, const [_aviso]);

    final icon = _icon(tester);
    expect(icon.icon, Icons.warning_amber_outlined);
    expect(icon.color, _colors.warning);
    expect(icon.semanticLabel, 'Aviso');
  });

  testWidgets('erro prevalece quando o nó tem erro e aviso juntos', (
    tester,
  ) async {
    await _pump(tester, const [_aviso, _erro]);

    expect(_icon(tester).icon, Icons.error_outline);
  });

  testWidgets('o tooltip traz as mensagens, uma por linha', (tester) async {
    await _pump(tester, const [_erro, _aviso]);

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, '${_erro.message}\n${_aviso.message}');
  });
}
