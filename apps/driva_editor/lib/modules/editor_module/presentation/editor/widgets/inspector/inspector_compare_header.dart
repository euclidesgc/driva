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
    this.changedPropertyKeys = const {},
    this.descriptor,
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

  /// Vem do kernel para não divergir do cálculo que decide, campo a campo,
  /// se `PropFieldCompareBinding` oferece "trazer o valor desta versão".
  final Set<String> changedPropertyKeys;

  final WidgetDescriptor? descriptor;

  final int candidateVersion;
  final ValueChanged<String> onCopyNodeProperties;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.inkSecondary,
    );
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

    final descriptor = this.descriptor;
    final unmappedPropertyKeys = descriptor == null
        ? const <String>{}
        : {
            for (final key in changedPropertyKeys)
              if (descriptor.fieldOf(key) == null) key,
          };

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
            style: secondaryStyle,
          ),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final kind in chips) VersionCompareMarkerChip(kind: kind),
            ],
          ),
          if (changedPropertyKeys.isNotEmpty)
            Text(
              _propertyCountLabel(changedPropertyKeys.length),
              style: secondaryStyle,
            ),
          if (unmappedPropertyKeys.isNotEmpty)
            Text(
              _unmappedPropertyKeysLabel(unmappedPropertyKeys),
              style: secondaryStyle,
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
              style: secondaryStyle,
            ),
        ],
      ),
    );
  }
}

String _propertyCountLabel(int count) => count == 1
    ? '1 propriedade alterada nesta versão'
    : '$count propriedades alteradas nesta versão';

String _unmappedPropertyKeysLabel(Set<String> keys) {
  final sorted = keys.toList()..sort();
  return 'Sem campo no Inspector para ${sorted.join(', ')} — só "Trazer '
      'todas as propriedades desta versão" alcança essas.';
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
