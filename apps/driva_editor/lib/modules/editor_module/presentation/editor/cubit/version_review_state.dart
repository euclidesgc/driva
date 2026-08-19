part of 'version_review_cubit.dart';

sealed class VersionReviewState extends Equatable {
  const VersionReviewState();
  @override
  List<Object?> get props => [];
}

final class VersionReviewLoading extends VersionReviewState {
  const VersionReviewLoading();
}

final class VersionReviewLoadFailure extends VersionReviewState {
  const VersionReviewLoadFailure({required this.failure});
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

final class VersionReviewLoaded extends VersionReviewState {
  const VersionReviewLoaded({required this.version});
  final LoadedContentVersion version;
  @override
  List<Object?> get props => [version];
}
