import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart';

/// Um checkpoint com o spec dentro — o que permite vê-lo e compará-lo, igual
/// a uma versão publicada, sem que ele tenha ido ao ar.
class LoadedContentCheckpoint extends Equatable {
  const LoadedContentCheckpoint({
    required this.id,
    required this.spec,
    required this.createdAt,
    this.note,
    this.createdBy,
  });

  final String id;
  final ContentSpec spec;
  final DateTime createdAt;
  final String? note;
  final String? createdBy;

  @override
  List<Object?> get props => [id, spec, createdAt, note, createdBy];
}
