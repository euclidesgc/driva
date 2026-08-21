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
/// Puramente informativo: a restauração é sempre da versão inteira, pela
/// seta `Carregar versão inteira no rascunho` da barra da candidata — este
/// cabeçalho não oferece nenhum controle de cópia por nó ou por propriedade.
class InspectorCompareHeader extends StatelessWidget {
  const InspectorCompareHeader({
    required this.candidateVersion,
    this.diff,
    this.isOnlyInDraft = false,
    this.isOnlyInVersion = false,
    this.safeAreaChanged = false,
    this.changedMetadataFields = const {},
    this.changedPropertyKeys = const {},
    this.descriptor,
    super.key,
  });

  final NodeDiff? diff;
  final bool isOnlyInDraft;
  final bool isOnlyInVersion;
  final bool safeAreaChanged;
  final Set<String> changedMetadataFields;

  /// Vem do kernel só para a contagem e para nomear as chaves sem campo no
  /// Inspector — leitura, não gatilho de cópia.
  final Set<String> changedPropertyKeys;

  final WidgetDescriptor? descriptor;

  final int candidateVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.inkSecondary,
    );

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

    final typeChanged = diff?.typeChanged ?? false;

    // Propriedades de tipos diferentes não se correspondem — comparar suas
    // chaves não tem significado, então o cabeçalho ignora o que veio mesmo
    // se o chamador as passar por engano.
    final propertyKeysForDisplay = typeChanged
        ? const <String>{}
        : changedPropertyKeys;
    final descriptor = typeChanged ? null : this.descriptor;
    final unmappedPropertyKeys = descriptor == null
        ? const <String>{}
        : {
            for (final key in propertyKeysForDisplay)
              if (descriptor.fieldOf(key) == null) key,
          };

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
          if (propertyKeysForDisplay.isNotEmpty)
            Text(
              _propertyCountLabel(propertyKeysForDisplay.length),
              style: secondaryStyle,
            ),
          if (unmappedPropertyKeys.isNotEmpty)
            Text(
              _unmappedPropertyKeysLabel(unmappedPropertyKeys),
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
  return 'Sem campo no Inspector para ${sorted.join(', ')} — para trazer '
      'essas mudanças, use a seta "Carregar versão inteira no rascunho" na '
      'barra da versão comparada.';
}
