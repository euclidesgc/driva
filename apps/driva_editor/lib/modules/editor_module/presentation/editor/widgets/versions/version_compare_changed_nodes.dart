import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_node_row.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Nós presentes nos dois lados com propriedade, evento ou tipo diferente
/// (T5, item 50). Nós idênticos e diferenças só de ordem/pai (`NodeDiff`
/// as reporta, mas fora do vocabulário de marcadores desta v1) não geram
/// linha — não há seta nem leitura para eles.
class VersionCompareChangedNodes extends StatelessWidget {
  const VersionCompareChangedNodes({
    required this.nodeDiffs,
    required this.canCopy,
    required this.onCopy,
    super.key,
  });

  final List<NodeDiff> nodeDiffs;
  final bool canCopy;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final visible = nodeDiffs
        .where(
          (diff) =>
              diff.propertiesChanged || diff.eventsChanged || diff.typeChanged,
        )
        .toList();

    if (visible.isEmpty) {
      return Text(
        'Nenhuma propriedade, evento ou tipo mudou nos nós em comum.',
        style: TextStyle(color: colors.inkMuted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final diff in visible)
          VersionCompareNodeRow(
            diff: diff,
            onCopy: canCopy && !diff.typeChanged && diff.propertiesChanged
                ? () => onCopy(diff.nodeId)
                : null,
          ),
      ],
    );
  }
}
