part of 'page_list_cubit.dart';

sealed class PageListState extends Equatable {
  const PageListState();
  @override
  List<Object?> get props => [];
}

final class PageListLoading extends PageListState {
  const PageListLoading();
}

/// Nenhuma página ainda: tem UX própria (orientação de primeiro uso).
final class PageListEmpty extends PageListState {
  const PageListEmpty();
}

final class PageListLoaded extends PageListState {
  final List<PageSummary> pages;
  const PageListLoaded({required this.pages});
  @override
  List<Object?> get props => [pages];
}

final class PageListError extends PageListState {
  final Failure failure;
  const PageListError({required this.failure});
  @override
  List<Object?> get props => [failure];
}
