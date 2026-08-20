import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:flutter/material.dart';

/// O alternador compartilhado do compacto (T5, item 50): controla, ao
/// mesmo tempo, qual preview aparece (`VersionComparePreviewSection`) e
/// qual coluna de nós exclusivos aparece (`VersionCompareExclusiveNodes`)
/// — um único controle, não um por seção, para não duplicar a mesma
/// decisão em dois lugares da tela. Rótulos genéricos ("Base"/"Candidata"),
/// porque a base pode ser o rascunho ou a versão no ar — só o rótulo do
/// preview em si (`VersionComparePreviewPane.label`) precisa dizer qual.
class VersionCompareSideToggle extends StatelessWidget {
  const VersionCompareSideToggle({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final VersionCompareVisibleSide selected;
  final ValueChanged<VersionCompareVisibleSide> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<VersionCompareVisibleSide>(
      segments: const [
        ButtonSegment(
          value: VersionCompareVisibleSide.base,
          label: Text('Base'),
        ),
        ButtonSegment(
          value: VersionCompareVisibleSide.candidate,
          label: Text('Candidata'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
