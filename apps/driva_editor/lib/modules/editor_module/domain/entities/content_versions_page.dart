import 'package:driva_editor/modules/editor_module/domain/entities/content_version.dart';
import 'package:equatable/equatable.dart';

class ContentVersionsPage extends Equatable {
  const ContentVersionsPage({required this.items, this.nextCursor});

  final List<ContentVersion> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}
