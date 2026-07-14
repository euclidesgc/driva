import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/theme/editor_colors.dart';

class JsonToolbar extends StatelessWidget {
  const JsonToolbar({super.key, required this.copied, required this.onCopy});

  final bool copied;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.data_object, size: 16, color: colors.inkMuted),
          const SizedBox(width: AppSpacing.s8),
          Text(
            'JSON do spec (somente-leitura)',
            style: TextStyle(
              fontSize: AppTypography.md,
              color: colors.inkSecondary,
            ),
          ),
          const Spacer(),
          // Estado do copiar não fica só na cor: ícone + rótulo mudam juntos.
          TextButton.icon(
            onPressed: () => onCopy(),
            icon: Icon(
              copied ? Icons.check : Icons.copy_all_outlined,
              size: 16,
              color: copied ? colors.success : colors.inkPrimary,
            ),
            label: Text(
              copied ? 'Copiado' : 'Copiar',
              style: TextStyle(
                fontSize: AppTypography.md,
                color: copied ? colors.success : colors.inkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
