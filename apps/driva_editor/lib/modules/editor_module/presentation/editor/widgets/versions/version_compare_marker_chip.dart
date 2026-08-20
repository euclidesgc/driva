import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:flutter/material.dart';

/// Um marcador da comparação (T5, item 50): ícone + texto + cor sobre uma
/// pílula neutra — a cor nunca é o único sinal, e nunca vive numa cor de
/// preenchimento que exigiria um token "on" que o tema não tem.
class VersionCompareMarkerChip extends StatelessWidget {
  const VersionCompareMarkerChip({required this.kind, super.key});

  final VersionCompareMarkerKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final tone = kind.tone(colors);
    final message = kind.isReadOnly
        ? '${kind.label} — somente leitura nesta versão do Driva'
        : kind.label;

    return Tooltip(
      message: message,
      child: Semantics(
        label: message,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s3,
          ),
          decoration: BoxDecoration(
            color: colors.panelAlt,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(kind.icon, size: AppIconSizes.s13, color: tone),
              const SizedBox(width: AppSpacing.s4),
              Text(
                kind.label,
                style: TextStyle(
                  fontSize: AppTypography.sm,
                  color: tone,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
