import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_exclusive_node_tile.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Uma das duas colunas de `VersionCompareExclusiveNodes`: os nós que só
/// existem num dos lados. Tipo é resolvido no spec de origem porque
/// `SpecComparisonResult` só guarda o `id` — a árvore ainda está aqui.
class VersionCompareExclusiveList extends StatelessWidget {
  const VersionCompareExclusiveList({
    required this.ids,
    required this.spec,
    required this.kind,
    required this.emptyLabel,
    this.labelOverride,
    super.key,
  });

  final Set<String> ids;
  final ContentSpec spec;
  final VersionCompareMarkerKind kind;
  final String emptyLabel;
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    if (ids.isEmpty) {
      return Text(emptyLabel, style: TextStyle(color: colors.inkMuted));
    }

    final sortedIds = ids.toList()..sort();
    final root = spec.root;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final id in sortedIds)
          VersionCompareExclusiveNodeTile(
            nodeId: id,
            nodeType: root == null ? null : findNode(root, id)?.type,
            kind: kind,
            labelOverride: labelOverride,
          ),
      ],
    );
  }
}
