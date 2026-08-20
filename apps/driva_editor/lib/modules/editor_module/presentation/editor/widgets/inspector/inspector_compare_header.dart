import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_marker_chip.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// O que muda no nó selecionado em relação à versão comparada, no topo do
/// Inspector — é aqui que a diferença encontra o usuário, ao lado do campo
/// que ele editaria.
///
/// Quando o nó só existe de um lado ou o tipo mudou, **não há botão**: trazer
/// as propriedades exigiria mesmo id e mesmo tipo, e um botão desabilitado
/// deixaria o usuário procurando o que destravaria — o cabeçalho explica e
/// aponta a alternativa segura.
class InspectorCompareHeader extends StatelessWidget {
  const InspectorCompareHeader({
    required this.candidateVersion,
    required this.onCopyNodeProperties,
    this.nodeId,
    this.diff,
    this.isOnlyInDraft = false,
    this.isOnlyInVersion = false,
    this.safeAreaChanged = false,
    this.changedMetadataFields = const {},
    super.key,
  });

  /// `null` no modo página, em que o cabeçalho mostra só o que é da página:
  /// safe area e metadados.
  final String? nodeId;

  final NodeDiff? diff;
  final bool isOnlyInDraft;
  final bool isOnlyInVersion;
  final bool safeAreaChanged;
  final Set<String> changedMetadataFields;
  final int candidateVersion;
  final ValueChanged<String> onCopyNodeProperties;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final id = nodeId;

    final chips = <VersionCompareMarkerKind>[
      if (isOnlyInDraft) VersionCompareMarkerKind.onlyInBase,
      if (isOnlyInVersion) VersionCompareMarkerKind.onlyInCandidate,
      if (diff?.typeChanged ?? false) VersionCompareMarkerKind.typeChanged,
      if (diff?.propertiesChanged ?? false)
        VersionCompareMarkerKind.propertiesChanged,
      if (diff?.eventsChanged ?? false) VersionCompareMarkerKind.eventsChanged,
      if (safeAreaChanged) VersionCompareMarkerKind.safeAreaChanged,
      if (changedMetadataFields.isNotEmpty)
        VersionCompareMarkerKind.metadataChanged,
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    final canCopy =
        id != null &&
        !isOnlyInDraft &&
        !isOnlyInVersion &&
        (diff?.propertiesChanged ?? false) &&
        !(diff?.typeChanged ?? false);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.panelAlt,
        borderRadius: BorderRadius.circular(AppRadii.r8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s8,
        children: [
          Text(
            'Comparando com a versão $candidateVersion',
            style: TextStyle(color: colors.inkSecondary),
          ),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final kind in chips) VersionCompareMarkerChip(kind: kind),
            ],
          ),
          if (canCopy)
            OutlinedButton.icon(
              onPressed: () => onCopyNodeProperties(id),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Trazer todas as propriedades desta versão'),
            )
          else if (id != null)
            Text(
              _whyNoButton(
                isOnlyInDraft: isOnlyInDraft,
                isOnlyInVersion: isOnlyInVersion,
                typeChanged: diff?.typeChanged ?? false,
                candidateVersion: candidateVersion,
              ),
              style: TextStyle(color: colors.inkSecondary),
            ),
        ],
      ),
    );
  }
}

String _whyNoButton({
  required bool isOnlyInDraft,
  required bool isOnlyInVersion,
  required bool typeChanged,
  required int candidateVersion,
}) {
  if (isOnlyInDraft) {
    return 'Este widget não existe na versão $candidateVersion, então não há '
        'propriedades para trazer. Para ficar com a versão inteira, use '
        'Carregar versão inteira no rascunho.';
  }
  if (isOnlyInVersion) {
    return 'Este widget existe só na versão $candidateVersion. Trazer um '
        'widget novo mudaria a estrutura da árvore — para isso, use Carregar '
        'versão inteira no rascunho.';
  }
  if (typeChanged) {
    return 'O tipo do widget mudou entre as duas versões, e propriedades de '
        'tipos diferentes não se correspondem. Para ficar com a versão '
        'inteira, use Carregar versão inteira no rascunho.';
  }
  return 'Eventos, safe area e metadados são somente leitura nesta versão do '
      'Driva. Para ficar com a versão inteira, use Carregar versão inteira '
      'no rascunho.';
}
