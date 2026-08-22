part of 'loaded_history_entry.dart';

class LoadedContentVersion extends LoadedHistoryEntry {
  const LoadedContentVersion({
    required this.version,
    required this.spec,
    required this.createdAt,
    this.note,
    this.createdBy,
  });

  final int version;
  @override
  final ContentSpec spec;
  @override
  final DateTime createdAt;
  @override
  final String? note;
  final String? createdBy;

  @override
  List<Object?> get props => [version, spec, createdAt, note, createdBy];
}
