import 'package:driva_editor/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// ID duplicado bloqueia a comparação inteira (T5, item 50, item 4): nenhuma
/// seta é exibida, o documento não é mutado, e a única saída é carregar a
/// versão inteira — a mesma alternativa segura de qualquer diferença que a
/// cópia seletiva não alcança.
class VersionCompareUnsafeView extends StatelessWidget {
  const VersionCompareUnsafeView({
    required this.failure,
    required this.onLoadFullVersion,
    super.key,
  });

  final ComparisonFailure failure;
  final VoidCallback onLoadFullVersion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final message = switch (failure) {
      DuplicateNodeIdComparisonFailure() =>
        'Esta versão não pode ser comparada com segurança: há um ID '
            'duplicado numa das árvores, o que tornaria qualquer cópia '
            'ambígua. Nenhuma seta é exibida, e nada foi alterado no '
            'rascunho.',
      _ => 'Esta versão não pode ser comparada com segurança.',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.panelAlt,
        border: Border.all(color: colors.danger),
        borderRadius: BorderRadius.circular(AppRadii.r8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: colors.danger,
                size: AppIconSizes.s18,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  message,
                  softWrap: true,
                  style: TextStyle(color: colors.inkPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          OutlinedButton(
            onPressed: onLoadFullVersion,
            child: const Text('Carregar versão inteira no rascunho'),
          ),
        ],
      ),
    );
  }
}
