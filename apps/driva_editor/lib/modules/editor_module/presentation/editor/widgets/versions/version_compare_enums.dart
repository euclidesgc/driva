import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// Qual coluna exclusiva o controle segmentado do compacto mostra em
/// `VersionCompareExclusiveNodes` — nada a ver com `VersionComparisonBase`
/// (que escolhe o spec comparado); este é só um filtro de exibição local.
enum VersionCompareVisibleSide { base, candidate }

/// Vocabulário de marcadores da comparação (T5, item 50) — sempre ícone +
/// texto + cor, nunca cor sozinha. `isReadOnly` marca os três tipos que a
/// v1 só declara, nunca copia (eventos, safe area, metadados).
enum VersionCompareMarkerKind {
  propertiesChanged,
  eventsChanged,
  safeAreaChanged,
  metadataChanged,
  onlyInBase,
  onlyInCandidate,
  typeChanged;

  String get label => switch (this) {
    VersionCompareMarkerKind.propertiesChanged => 'Propriedades alteradas',
    VersionCompareMarkerKind.eventsChanged => 'Eventos alterados',
    VersionCompareMarkerKind.safeAreaChanged => 'Safe area alterada',
    VersionCompareMarkerKind.metadataChanged => 'Metadados alterados',
    VersionCompareMarkerKind.onlyInBase => 'Somente no rascunho',
    VersionCompareMarkerKind.onlyInCandidate => 'Somente na versão',
    VersionCompareMarkerKind.typeChanged => 'Tipo mudou',
  };

  IconData get icon => switch (this) {
    VersionCompareMarkerKind.propertiesChanged => Icons.tune,
    VersionCompareMarkerKind.eventsChanged => Icons.bolt_outlined,
    VersionCompareMarkerKind.safeAreaChanged => Icons.crop_free,
    VersionCompareMarkerKind.metadataChanged => Icons.info_outline,
    VersionCompareMarkerKind.onlyInBase => Icons.remove_circle_outline,
    VersionCompareMarkerKind.onlyInCandidate => Icons.add_circle_outline,
    VersionCompareMarkerKind.typeChanged => Icons.swap_horiz,
  };

  bool get isReadOnly => switch (this) {
    VersionCompareMarkerKind.eventsChanged ||
    VersionCompareMarkerKind.safeAreaChanged ||
    VersionCompareMarkerKind.metadataChanged => true,
    _ => false,
  };

  Color tone(EditorColors colors) => switch (this) {
    VersionCompareMarkerKind.propertiesChanged => colors.success,
    VersionCompareMarkerKind.typeChanged => colors.danger,
    _ => colors.warning,
  };
}
