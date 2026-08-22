part of 'version_compare_mode_cubit.dart';

sealed class VersionCompareModeState extends Equatable {
  const VersionCompareModeState();
  @override
  List<Object?> get props => [];
}

final class VersionCompareModeInactive extends VersionCompareModeState {
  const VersionCompareModeInactive();
}

final class VersionCompareModeLoading extends VersionCompareModeState {
  const VersionCompareModeLoading({
    this.candidateVersion,
    this.candidateCheckpointId,
  });

  final int? candidateVersion;
  final String? candidateCheckpointId;

  @override
  List<Object?> get props => [candidateVersion, candidateCheckpointId];
}

final class VersionCompareModeActive extends VersionCompareModeState {
  const VersionCompareModeActive({
    required this.candidate,
    required this.baseSpec,
    required this.result,
    this.versions = const [],
    this.checkpoints = const [],
    this.nextCursor,
    this.checkpointsCursor,
    this.isLoadingMore = false,
  });

  /// A entrada histórica escolhida, inerte no mock da direita — publicação
  /// ou ponto salvo.
  final LoadedHistoryEntry candidate;

  /// O rascunho ao vivo, sincronizado pelo `editorCubit.stream` a cada
  /// mudança — nunca a versão publicada: escolher entre rascunho e versão no
  /// ar como base morreu junto com o modal, porque o lado esquerdo passou a
  /// ser o canvas ao vivo.
  final ContentSpec baseSpec;

  final Either<ComparisonFailure, SpecComparisonResult> result;

  /// Publicações e pontos salvos já carregados, cada lista com o próprio
  /// cursor — as duas espécies paginam por chaves diferentes (número vs.
  /// data), igual a `VersionHistoryLoaded`. [entries] é quem os mescla na
  /// ordem que o `‹`/`›` da barra da candidata percorre.
  final List<ContentVersion> versions;
  final List<ContentCheckpoint> checkpoints;
  final String? nextCursor;
  final String? checkpointsCursor;
  final bool isLoadingMore;

  List<ContentHistoryEntry> get entries =>
      mergeHistoryEntries(versions: versions, checkpoints: checkpoints);

  bool get hasMoreHistory => nextCursor != null || checkpointsCursor != null;

  int get _candidateIndex => entries.indexWhere(
    (entry) => switch ((entry, candidate)) {
      (
        PublishedVersionEntry(version: final v),
        LoadedContentVersion(:final version),
      ) =>
        v.version == version,
      (
        CheckpointEntry(checkpoint: final c),
        LoadedContentCheckpoint(:final id),
      ) =>
        c.id == id,
      _ => false,
    },
  );

  /// `‹`/`›` só navegam quando a candidata aparece na linha do tempo já
  /// carregada — sem ela (ex.: um checkpoint revisado sem a lista de pontos
  /// salvos ter chegado), não há vizinho para achar, e um botão que nunca
  /// reage é pior que um botão desabilitado.
  bool get canNavigateHistory => _candidateIndex >= 0;

  VersionCompareModeActive copyWith({
    LoadedHistoryEntry? candidate,
    ContentSpec? baseSpec,
    Either<ComparisonFailure, SpecComparisonResult>? result,
    List<ContentVersion>? versions,
    List<ContentCheckpoint>? checkpoints,
    String? Function()? nextCursor,
    String? Function()? checkpointsCursor,
    bool? isLoadingMore,
  }) {
    return VersionCompareModeActive(
      candidate: candidate ?? this.candidate,
      baseSpec: baseSpec ?? this.baseSpec,
      result: result ?? this.result,
      versions: versions ?? this.versions,
      checkpoints: checkpoints ?? this.checkpoints,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      checkpointsCursor: checkpointsCursor != null
          ? checkpointsCursor()
          : this.checkpointsCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    candidate,
    baseSpec,
    result,
    versions,
    checkpoints,
    nextCursor,
    checkpointsCursor,
    isLoadingMore,
  ];
}

final class VersionCompareModeFailure extends VersionCompareModeState {
  const VersionCompareModeFailure({
    required this.failure,
    this.candidateVersion,
    this.candidateCheckpointId,
  });

  final Failure failure;
  final int? candidateVersion;
  final String? candidateCheckpointId;

  @override
  List<Object?> get props => [
    failure,
    candidateVersion,
    candidateCheckpointId,
  ];
}
