import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:flutter/material.dart';

/// Um marcador da comparação (T5, item 50): ícone + texto + cor sobre uma
/// pílula neutra — a cor nunca é o único sinal, e nunca vive numa cor de
/// preenchimento que exigiria um token "on" que o tema não tem. Para os três
/// tipos que a v1 só declara (nunca copia), a declaração "somente leitura"
/// é texto de verdade na tela, não só `Tooltip`/`Semantics` — quem não usa
/// mouse nem leitor de tela também precisa enxergá-la.
class VersionCompareMarkerChip extends StatelessWidget {
  const VersionCompareMarkerChip({
    required this.kind,
    this.labelOverride,
    super.key,
  });

  final VersionCompareMarkerKind kind;

  /// Substitui `kind.label` quando o texto depende de algo em tempo de
  /// execução — hoje só `onlyInBase`, que nomeia a base exibida (rascunho
  /// ou a versão no ar), nunca "rascunho" fixo.
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final tone = kind.tone(colors);
    final label = labelOverride ?? kind.label;
    final message = kind.isReadOnly
        ? '$label — somente leitura nesta versão do Driva'
        : label;

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
                label,
                style: TextStyle(
                  fontSize: AppTypography.sm,
                  color: tone,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (kind.isReadOnly) ...[
                const SizedBox(width: AppSpacing.s4),
                Text(
                  '(somente leitura)',
                  style: TextStyle(
                    fontSize: AppTypography.sm,
                    color: colors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
