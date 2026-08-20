import 'package:driva_editor/modules/editor_module/domain/entities/content_checkpoint.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/content_version.dart';
import 'package:equatable/equatable.dart';

/// Uma linha do histórico, que mistura duas espécies com significados
/// diferentes: o que **esteve no ar** e o que foi apenas **marcado ao salvar**.
///
/// Elas convivem na mesma linha do tempo porque é assim que o autor pensa o
/// trabalho — em ordem cronológica —, mas nunca se confundem: só a publicação
/// tem número `vN`, e só ela foi servida a algum aplicativo.
sealed class ContentHistoryEntry extends Equatable {
  const ContentHistoryEntry();

  DateTime get createdAt;
  String? get note;
}

final class PublishedVersionEntry extends ContentHistoryEntry {
  const PublishedVersionEntry(this.version);

  final ContentVersion version;

  @override
  DateTime get createdAt => version.createdAt;

  @override
  String? get note => version.note;

  @override
  List<Object?> get props => [version];
}

final class CheckpointEntry extends ContentHistoryEntry {
  const CheckpointEntry(this.checkpoint);

  final ContentCheckpoint checkpoint;

  @override
  DateTime get createdAt => checkpoint.createdAt;

  @override
  String? get note => checkpoint.note;

  @override
  List<Object?> get props => [checkpoint];
}

/// Mescla as duas espécies em ordem cronológica decrescente.
///
/// O desempate por espécie não é estético: quando uma publicação e um ponto
/// marcado caem no mesmo instante — o publish que salva antes, por exemplo —,
/// a publicação vem primeiro, porque é a que mudou o que o usuário final vê.
List<ContentHistoryEntry> mergeHistoryEntries({
  required List<ContentVersion> versions,
  required List<ContentCheckpoint> checkpoints,
}) {
  final entries =
      <ContentHistoryEntry>[
        for (final version in versions) PublishedVersionEntry(version),
        for (final checkpoint in checkpoints) CheckpointEntry(checkpoint),
      ]..sort((a, b) {
        final byDate = b.createdAt.compareTo(a.createdAt);
        if (byDate != 0) return byDate;
        if (a is PublishedVersionEntry && b is CheckpointEntry) return -1;
        if (a is CheckpointEntry && b is PublishedVersionEntry) return 1;
        return 0;
      });
  return entries;
}
