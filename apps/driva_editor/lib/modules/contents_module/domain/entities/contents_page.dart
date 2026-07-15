import 'package:equatable/equatable.dart';

import 'content_summary.dart';

class ContentsPage extends Equatable {
  const ContentsPage({required this.items, this.nextCursor});

  final List<ContentSummary> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}
