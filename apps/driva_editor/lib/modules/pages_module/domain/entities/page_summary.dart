import 'package:equatable/equatable.dart';

/// Resumo de uma página para a listagem (o spec completo só é carregado no
/// editor).
class PageSummary extends Equatable {
  const PageSummary({
    required this.id,
    required this.name,
    required this.screenTarget,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// Tela do app à qual a página (fragmento) está anexada.
  final String screenTarget;

  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, name, screenTarget, updatedAt];
}
