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
  const ContentListLoaded({required this.contents});
  @override
  List<Object?> get props => [contents];
}

final class ContentListError extends ContentListState {
  final Failure failure;
  const ContentListError({required this.failure});
  @override
  List<Object?> get props => [failure];
}
