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
  const VersionCompareModeLoading({required this.candidateVersion});

  final int candidateVersion;

  @override
  List<Object?> get props => [candidateVersion];
}

final class VersionCompareModeActive extends VersionCompareModeState {
  const VersionCompareModeActive({
    required this.candidate,
    required this.baseSpec,
    required this.result,
    required this.versions,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  /// A versão histórica escolhida, inerte no mock da direita.
  final LoadedContentVersion candidate;

  /// O rascunho ao vivo, sincronizado pelo `editorCubit.stream` a cada
  /// mudança — nunca a versão publicada: escolher entre rascunho e versão no
  /// ar como base morreu junto com o modal, porque o lado esquerdo passou a
  /// ser o canvas ao vivo.
  final ContentSpec baseSpec;

  final Either<ComparisonFailure, SpecComparisonResult> result;

  /// Página(s) já carregadas do histórico, mais nova no índice 0 — o
  /// `‹`/`›` da barra da candidata navega por aqui antes de pedir mais.
  final List<ContentVersion> versions;
  final String? nextCursor;
  final bool isLoadingMore;

  VersionCompareModeActive copyWith({
    LoadedContentVersion? candidate,
    ContentSpec? baseSpec,
    Either<ComparisonFailure, SpecComparisonResult>? result,
    List<ContentVersion>? versions,
    String? Function()? nextCursor,
    bool? isLoadingMore,
  }) {
    return VersionCompareModeActive(
      candidate: candidate ?? this.candidate,
      baseSpec: baseSpec ?? this.baseSpec,
      result: result ?? this.result,
      versions: versions ?? this.versions,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    candidate,
    baseSpec,
    result,
    versions,
    nextCursor,
    isLoadingMore,
  ];
}

final class VersionCompareModeFailure extends VersionCompareModeState {
  const VersionCompareModeFailure({
    required this.failure,
    required this.candidateVersion,
  });

  final Failure failure;
  final int candidateVersion;

  @override
  List<Object?> get props => [failure, candidateVersion];
}
