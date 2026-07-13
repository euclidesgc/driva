import 'package:equatable/equatable.dart';

import 'content_summary.dart';

/// Uma página de conteúdos: o envelope `{ data, nextCursor }` do contrato
/// `GET /v1/contents`, já como entidade de domain (Dart puro).
///
/// `nextCursor` nulo é o sinal de última página. O cursor é opaco — o domain
/// só o repassa de volta na próxima chamada, nunca o interpreta.
class ContentsPage extends Equatable {
  const ContentsPage({required this.items, this.nextCursor});

  final List<ContentSummary> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}
