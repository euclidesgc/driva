import 'package:driva_editor/modules/editor_module/domain/entities/content_checkpoint.dart';
import 'package:equatable/equatable.dart';

class ContentCheckpointsPage extends Equatable {
  const ContentCheckpointsPage({required this.items, this.nextCursor});

  final List<ContentCheckpoint> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}
