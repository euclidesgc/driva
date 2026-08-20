import 'package:driva_editor/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Alternativa segura para o que a cópia seletiva não alcança — estrutura,
/// tipo, eventos, safe area ou metadados (T5, item 50, item 4). Só existe
/// nesta versão: `Carregar versão inteira no rascunho`.
class VersionCompareFullLoadBanner extends StatelessWidget {
  const VersionCompareFullLoadBanner({
    required this.reasons,
    required this.onPressed,
    super.key,
  });

  final List<String> reasons;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.panelAlt,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadii.r8),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.s12,
        runSpacing: AppSpacing.s8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: colors.inkSecondary,
                size: AppIconSizes.s18,
              ),
              const SizedBox(width: AppSpacing.s8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.s320),
                child: Text(
                  'Esta versão tem diferenças que a seta não alcança '
                  '(${reasons.join(", ")}). Para trazê-las, carregue a '
                  'versão inteira.',
                  softWrap: true,
                  style: TextStyle(color: colors.inkSecondary),
                ),
              ),
            ],
          ),
          OutlinedButton(
            onPressed: onPressed,
            child: const Text('Carregar versão inteira no rascunho'),
          ),
        ],
      ),
    );
  }
}
