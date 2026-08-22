part of 'loaded_history_entry.dart';

/// Um checkpoint com o spec dentro — o que permite vê-lo e compará-lo, igual
/// a uma versão publicada, sem que ele tenha ido ao ar.
class LoadedContentCheckpoint extends LoadedHistoryEntry {
  const LoadedContentCheckpoint({
    required this.id,
    required this.spec,
    required this.createdAt,
    this.note,
    this.createdBy,
  });

  final String id;
  @override
  final ContentSpec spec;
  @override
  final DateTime createdAt;
  @override
  final String? note;
  final String? createdBy;

  @override
  List<Object?> get props => [id, spec, createdAt, note, createdBy];
}
