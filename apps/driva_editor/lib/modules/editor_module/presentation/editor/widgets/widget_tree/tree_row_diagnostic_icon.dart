import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/node_diagnostics_summary.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Ícone + tooltip na linha da árvore — cor nunca é o único sinal do
/// problema apontado pelo `diagnoseTree`.
class TreeRowDiagnosticIcon extends StatelessWidget {
  const TreeRowDiagnosticIcon({required this.diagnostics, super.key});

  final List<SpecDiagnostic> diagnostics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final summary = summarizeDiagnostics(diagnostics);
    final isError = summary.severity == DiagnosticSeverity.error;
    return Tooltip(
      message: summary.message,
      child: Icon(
        isError ? Icons.error_outline : Icons.warning_amber_outlined,
        size: AppIconSizes.s18,
        color: isError ? colors.danger : colors.warning,
        semanticLabel: isError ? 'Erro' : 'Aviso',
      ),
    );
  }
}
