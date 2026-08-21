import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// Conteúdo do lado esquerdo de `VersionCompareModeBar`: identifica o
/// rascunho na barra única do modo de comparação lado a lado, e diz que ele
/// está congelado — o cadeado e o texto dizem a mesma coisa, porque o
/// esmaecido dos painéis sozinho não é sinal de nada.
class CanvasCompareDraftLegend extends StatelessWidget {
  const CanvasCompareDraftLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    const label = 'Rascunho (somente leitura)';
    return Tooltip(
      message: 'Seu rascunho, congelado enquanto a comparação está aberta',
      child: Semantics(
        label: 'Rascunho — somente leitura enquanto a comparação está aberta',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: AppIconSizes.s16,
              color: colors.inkSecondary,
            ),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.inkPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
