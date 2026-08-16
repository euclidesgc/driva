part of 'preview_cubit.dart';

sealed class PreviewState extends Equatable {
  const PreviewState();
  @override
  List<Object?> get props => [];
}

final class PreviewLoading extends PreviewState {
  const PreviewLoading();
}

final class PreviewReady extends PreviewState {
  const PreviewReady({
    required this.spec,
    required this.fetchedAt,
    this.refreshFailure,
  });

  /// Fonte de verdade única da tela: o que o `SduiView` desenha.
  final ContentSpec spec;

  /// Quando esta busca terminou — a base da pílula "último salvo" (D4).
  final DateTime fetchedAt;

  /// Falha do último `refresh()` (D30): sinal à parte, nunca troca de estado
  /// — trocar de estado apagaria o conteúdo que ainda está na tela.
  final Failure? refreshFailure;

  PreviewReady copyWith({Failure? refreshFailure}) => PreviewReady(
    spec: spec,
    fetchedAt: fetchedAt,
    refreshFailure: refreshFailure ?? this.refreshFailure,
  );

  @override
  List<Object?> get props => [spec, fetchedAt, refreshFailure];
}

final class PreviewFailure extends PreviewState {
  const PreviewFailure({required this.failure});

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
