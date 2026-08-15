part of 'content_cubit.dart';

sealed class ContentState extends Equatable {
  const ContentState();

  @override
  List<Object?> get props => [];
}

final class ContentLoading extends ContentState {
  const ContentLoading();
}

final class ContentLoaded extends ContentState {
  const ContentLoaded({required this.content});

  final PublishedContent content;

  @override
  List<Object?> get props => [content];
}

final class ContentError extends ContentState {
  const ContentError({required this.failure});

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
