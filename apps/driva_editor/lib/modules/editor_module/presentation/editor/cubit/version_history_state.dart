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
    this.checkpoints = const [],
    this.publishedVersion,
    this.nextCursor,
    this.checkpointsCursor,
    this.isLoadingMore = false,
  });

  final List<ContentVersion> versions;

  /// Os pontos marcados ao salvar. Lista separada, e não misturada em
  /// [versions], porque as duas espécies paginam por chaves diferentes e
  /// significam coisas diferentes — quem as junta para exibição é
  /// [entries].
  final List<ContentCheckpoint> checkpoints;

  final int? publishedVersion;
  final String? nextCursor;
  final String? checkpointsCursor;
  final bool isLoadingMore;

  /// A linha do tempo como a tela mostra: as duas espécies em ordem
  /// cronológica, cada uma ainda reconhecível.
  List<ContentHistoryEntry> get entries =>
      mergeHistoryEntries(versions: versions, checkpoints: checkpoints);

  bool get hasMore => nextCursor != null || checkpointsCursor != null;

  VersionHistoryLoaded copyWith({
    List<ContentVersion>? versions,
    List<ContentCheckpoint>? checkpoints,
    String? Function()? nextCursor,
    String? Function()? checkpointsCursor,
    bool? isLoadingMore,
  }) {
    return VersionHistoryLoaded(
      versions: versions ?? this.versions,
      checkpoints: checkpoints ?? this.checkpoints,
      publishedVersion: publishedVersion,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      checkpointsCursor: checkpointsCursor != null
          ? checkpointsCursor()
          : this.checkpointsCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    versions,
    checkpoints,
    publishedVersion,
    nextCursor,
    checkpointsCursor,
    isLoadingMore,
  ];
}
