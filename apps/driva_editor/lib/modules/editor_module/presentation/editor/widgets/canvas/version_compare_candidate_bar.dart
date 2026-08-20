import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_readonly_badge.dart';
import 'package:flutter/material.dart';

/// Barra do mock da direita, na mesma altura da `CanvasToolbar` do lado
/// esquerdo para os dois mocks começarem na mesma linha. Concentra o que é
/// específico da versão comparada: qual é, que é somente leitura, como
/// andar para a anterior/seguinte e como sair do modo.
class VersionCompareCandidateBar extends StatelessWidget {
  const VersionCompareCandidateBar({
    required this.candidateVersion,
    required this.onOlder,
    required this.onNewer,
    required this.onClose,
    super.key,
  });

  final int candidateVersion;

  /// `null` desabilita: não há versão mais antiga carregada nem próxima
  /// página para pedir.
  final VoidCallback? onOlder;

  /// `null` na versão mais nova do histórico.
  final VoidCallback? onNewer;

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        height: AppSizes.canvasToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        decoration: BoxDecoration(
          color: colors.panel,
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          spacing: AppSpacing.s8,
          children: [
            Icon(
              Icons.history,
              size: AppIconSizes.s16,
              color: colors.inkSecondary,
            ),
            Flexible(
              child: Text(
                'Versão $candidateVersion',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(color: colors.inkPrimary),
              ),
            ),
            if (constraints.maxWidth >=
                AppSizes.versionCompareBarLabelsFitWidth)
              const VersionReadonlyBadge(),
            const Spacer(),
            IconButton(
              onPressed: onNewer,
              tooltip: 'Versão mais nova',
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: onOlder,
              tooltip: 'Versão mais antiga',
              icon: const Icon(Icons.chevron_right),
            ),
            if (constraints.maxWidth >=
                AppSizes.versionCompareBarLabelsFitWidth)
              TextButton.icon(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: AppIconSizes.s18),
                label: const Text('Fechar comparação'),
              )
            else
              IconButton(
                onPressed: onClose,
                tooltip: 'Fechar comparação',
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }
}
