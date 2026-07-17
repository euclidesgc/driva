import 'package:driva_editor/modules/contents_module/domain/entities/content_summary.dart';
import 'package:equatable/equatable.dart';

class ContentsPage extends Equatable {
  const ContentsPage({required this.items, this.nextCursor});

  final List<ContentSummary> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}
