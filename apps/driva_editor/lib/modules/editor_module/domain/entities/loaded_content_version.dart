import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart';

class LoadedContentVersion extends Equatable {
  const LoadedContentVersion({
    required this.version,
    required this.spec,
    required this.createdAt,
    this.note,
    this.createdBy,
  });

  final int version;
  final ContentSpec spec;
  final DateTime createdAt;
  final String? note;
  final String? createdBy;

  @override
  List<Object?> get props => [version, spec, createdAt, note, createdBy];
}
