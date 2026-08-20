import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_row_action_button.dart';
import 'package:flutter/material.dart';

/// As três ações de uma linha do histórico (item 50): `Ver` é a única
/// primária — escolher uma versão para olhar nunca é destrutivo, então é ela
/// quem chama mais atenção. `Comparar` fica desabilitada só quando
/// `onCompare` é nulo (uso sem `VersionHistoryDialog`, ex. teste isolado).
class VersionRowActions extends StatelessWidget {
  const VersionRowActions({
    required this.onView,
    required this.onLoadToDraft,
    this.onCompare,
    super.key,
  });

  final VoidCallback onView;
  final VoidCallback onLoadToDraft;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        VersionRowActionButton(
          label: 'Ver',
          icon: Icons.visibility_outlined,
          tooltip: 'Ver esta versão sem alterar o rascunho',
          onPressed: onView,
          isPrimary: true,
        ),
        VersionRowActionButton(
          label: 'Comparar',
          icon: Icons.compare_arrows,
          tooltip: onCompare == null
              ? 'Comparar chega numa próxima etapa deste item'
              : 'Comparar esta versão com o rascunho',
          onPressed: onCompare,
        ),
        VersionRowActionButton(
          label: 'Carregar no rascunho',
          icon: Icons.file_download_outlined,
          tooltip: 'Substituir o rascunho local por esta versão',
          onPressed: onLoadToDraft,
        ),
      ],
    );
  }
}
