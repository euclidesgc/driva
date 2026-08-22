import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/history_entry_label.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_readonly_badge.dart';
import 'package:flutter/material.dart';

/// Barra do mock da direita, na mesma altura da `CanvasToolbar` do lado
/// esquerdo para os dois mocks começarem na mesma linha. Concentra o que é
/// específico da candidata comparada: qual é (publicação ou ponto salvo),
/// que é somente leitura, como andar para a anterior/seguinte, a seta que
/// restaura a candidata inteira no rascunho e como sair do modo.
///
/// A restauração é sempre da candidata inteira (decisão do dono: uma seta
/// só, referente a tudo) — não existe mais cópia por propriedade nem por nó.
class VersionCompareCandidateBar extends StatelessWidget {
  const VersionCompareCandidateBar({
    required this.candidate,
    required this.onOlder,
    required this.onNewer,
    required this.onLoadFullVersion,
    required this.onClose,
    super.key,
  });

  final LoadedHistoryEntry candidate;

  /// `null` desabilita: ou a candidata não aparece na linha do tempo já
  /// carregada, ou não há vizinho mais antigo nem próxima página para pedir.
  final VoidCallback? onOlder;

  /// `null` desabilita pelo mesmo motivo de [onOlder], ou porque a candidata
  /// já é a entrada mais nova do histórico.
  final VoidCallback? onNewer;

  final VoidCallback onLoadFullVersion;

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
                historyEntryCandidateLabel(candidate),
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
              tooltip: _newerTooltip,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: onOlder,
              tooltip: _olderTooltip,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              onPressed: onLoadFullVersion,
              tooltip: _loadFullEntryLabel(candidate),
              icon: const Icon(Icons.file_download_outlined),
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

const _olderTooltip = 'Item mais antigo do histórico';
const _newerTooltip = 'Item mais novo do histórico';

String _loadFullEntryLabel(LoadedHistoryEntry entry) => switch (entry) {
  LoadedContentVersion() => 'Carregar versão inteira no rascunho',
  LoadedContentCheckpoint() => 'Carregar o ponto salvo inteiro no rascunho',
};
