part of 'version_history_cubit.dart';

sealed class VersionHistoryState extends Equatable {
  const VersionHistoryState();
  @override
  List<Object?> get props => [];
}

final class VersionHistoryLoading extends VersionHistoryState {
  const VersionHistoryLoading();
}

final class VersionHistoryLoadFailure extends VersionHistoryState {
  const VersionHistoryLoadFailure({required this.failure});
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

final class VersionHistoryLoaded extends VersionHistoryState {
  const VersionHistoryLoaded({
    required this.versions,
    this.publishedVersion,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<ContentVersion> versions;
  final int? publishedVersion;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;

  VersionHistoryLoaded copyWith({
    List<ContentVersion>? versions,
    String? Function()? nextCursor,
    bool? isLoadingMore,
  }) {
    return VersionHistoryLoaded(
      versions: versions ?? this.versions,
      publishedVersion: publishedVersion,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    versions,
    publishedVersion,
    nextCursor,
    isLoadingMore,
  ];
}
