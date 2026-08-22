import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/checkpoint_row.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_row.dart';
import 'package:flutter/material.dart';

/// Escolhe a linha certa para cada espécie da linha do tempo — publicação e
/// ponto salvo têm as mesmas três ações (item 53).
class HistoryEntryRow extends StatelessWidget {
  const HistoryEntryRow({
    required this.entry,
    required this.onViewVersion,
    required this.onLoadVersionToDraft,
    required this.onViewCheckpoint,
    required this.onLoadCheckpointToDraft,
    this.publishedVersion,
    this.onCompareVersion,
    this.onCompareCheckpoint,
    super.key,
  });

  final ContentHistoryEntry entry;
  final int? publishedVersion;
  final ValueChanged<int> onViewVersion;
  final ValueChanged<int> onLoadVersionToDraft;
  final ValueChanged<int>? onCompareVersion;
  final ValueChanged<String> onViewCheckpoint;
  final ValueChanged<String> onLoadCheckpointToDraft;
  final ValueChanged<String>? onCompareCheckpoint;

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
        onView: onViewCheckpoint,
        onLoadToDraft: onLoadCheckpointToDraft,
        onCompare: onCompareCheckpoint,
      ),
    };
  }
}
