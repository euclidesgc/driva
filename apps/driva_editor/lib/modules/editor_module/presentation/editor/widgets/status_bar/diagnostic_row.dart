import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/palette_icons.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class DiagnosticRow extends StatelessWidget {
  const DiagnosticRow({
    required this.diagnostic,
    required this.onSelect,
    super.key,
  });

  final SpecDiagnostic diagnostic;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final isError = diagnostic.severity == DiagnosticSeverity.error;
    final tone = isError ? colors.danger : colors.warning;
    final label =
        descriptorFor(diagnostic.nodeType)?.label ?? diagnostic.nodeType;

    return Semantics(
      button: true,
      label: '${isError ? 'Erro' : 'Aviso'} em $label',
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.warning_amber_outlined,
                size: 16,
                color: tone,
              ),
              const SizedBox(width: AppSpacing.s8),
              Icon(
                paletteIconFor(diagnostic.nodeType),
                size: 14,
                color: colors.inkMuted,
              ),
              const SizedBox(width: AppSpacing.s6),
              Expanded(
                child: Text(
                  diagnostic.message,
                  style: TextStyle(
                    fontSize: AppTypography.sm,
                    color: colors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
