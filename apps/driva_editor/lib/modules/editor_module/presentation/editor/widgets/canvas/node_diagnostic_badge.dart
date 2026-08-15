import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/node_diagnostics_summary.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Selo aditivo sobre o nó no canvas: cor **e** ícone marcam a severidade, o
/// tooltip carrega a mensagem do `diagnoseTree` — cor nunca é o único sinal.
class NodeDiagnosticBadge extends StatelessWidget {
  const NodeDiagnosticBadge({required this.diagnostics, super.key});

  final List<SpecDiagnostic> diagnostics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final summary = summarizeDiagnostics(diagnostics);
    final isError = summary.severity == DiagnosticSeverity.error;
    return Tooltip(
      message: summary.message,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s2),
        decoration: BoxDecoration(
          color: isError ? colors.danger : colors.warning,
          borderRadius: BorderRadius.circular(AppRadii.r4),
        ),
        child: Icon(
          isError ? Icons.error_outline : Icons.warning_amber_outlined,
          size: AppIconSizes.s18,
          color: isError ? colors.onDanger : colors.onWarning,
          semanticLabel: isError ? 'Erro' : 'Aviso',
        ),
      ),
    );
  }
}
