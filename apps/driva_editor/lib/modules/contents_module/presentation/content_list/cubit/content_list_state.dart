part of 'content_list_cubit.dart';

sealed class ContentListState extends Equatable {
  const ContentListState();
  @override
  List<Object?> get props => [];
}

final class ContentListLoading extends ContentListState {
  const ContentListLoading();
}

/// Nenhum conteúdo ainda: tem UX própria (orientação de primeiro uso).
final class ContentListEmpty extends ContentListState {
  const ContentListEmpty();
}

final class ContentListLoaded extends ContentListState {
  final List<ContentSummary> contents;

  /// Cursor da próxima página (`nextCursor` do envelope); `null` = última
  /// página, não há mais o que carregar.
  final String? nextCursor;

  /// Carregando a próxima página (scroll infinito) — a UI mostra um rodapé de
  /// loading sem trocar o corpo da lista.
  final bool isLoadingMore;

  const ContentListLoaded({
    required this.contents,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  bool get hasMore => nextCursor != null;

  ContentListLoaded copyWith({
    List<ContentSummary>? contents,
    String? nextCursor,
    bool? isLoadingMore,
  }) => ContentListLoaded(
    contents: contents ?? this.contents,
    nextCursor: nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [contents, nextCursor, isLoadingMore];
}

final class ContentListError extends ContentListState {
  final Failure failure;
  const ContentListError({required this.failure});
  @override
  List<Object?> get props => [failure];
}
