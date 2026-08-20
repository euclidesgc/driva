import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/checkpoint_row.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_row.dart';
import 'package:flutter/material.dart';

/// Escolhe a linha certa para cada espécie da linha do tempo.
///
/// As ações de um ponto marcado ainda não existem — ver e comparar um
/// checkpoint são o passo seguinte —, e por isso chegam nulas: botão que não
/// faz nada é pior que botão ausente, porque promete algo que não acontece.
class HistoryEntryRow extends StatelessWidget {
  const HistoryEntryRow({
    required this.entry,
    required this.onViewVersion,
    required this.onLoadVersionToDraft,
    this.publishedVersion,
    this.onCompareVersion,
    super.key,
  });

  final ContentHistoryEntry entry;
  final int? publishedVersion;
  final ValueChanged<int> onViewVersion;
  final ValueChanged<int> onLoadVersionToDraft;
  final ValueChanged<int>? onCompareVersion;

  @override
  Widget build(BuildContext context) {
    return switch (entry) {
      PublishedVersionEntry(:final version) => VersionRow(
        version: version,
        isPublished: version.version == publishedVersion,
        onView: onViewVersion,
        onLoadToDraft: onLoadVersionToDraft,
        onCompare: onCompareVersion,
      ),
      CheckpointEntry(:final checkpoint) => CheckpointRow(
        checkpoint: checkpoint,
      ),
    };
  }
}
