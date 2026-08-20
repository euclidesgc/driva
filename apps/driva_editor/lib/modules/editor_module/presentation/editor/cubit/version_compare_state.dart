part of 'version_compare_cubit.dart';

sealed class VersionCompareState extends Equatable {
  const VersionCompareState();
  @override
  List<Object?> get props => [];
}

final class VersionCompareLoading extends VersionCompareState {
  const VersionCompareLoading();
}

final class VersionCompareLoadFailure extends VersionCompareState {
  const VersionCompareLoadFailure({required this.failure});
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

final class VersionCompareLoaded extends VersionCompareState {
  const VersionCompareLoaded({
    required this.candidate,
    required this.base,
    required this.baseSpec,
    required this.result,
    this.isLoadingPublishedBase = false,
  });

  final LoadedContentVersion candidate;
  final VersionComparisonBase base;

  /// O spec exibido como "base" — o rascunho ou, sob pedido, a versão no
  /// ar. Nunca o alvo direto de uma cópia quando é a versão no ar; ver
  /// `VersionCompareCubit.copyNodeProperties`.
  final ContentSpec baseSpec;
  final Either<ComparisonFailure, SpecComparisonResult> result;
  final bool isLoadingPublishedBase;

  VersionCompareLoaded copyWith({bool? isLoadingPublishedBase}) {
    return VersionCompareLoaded(
      candidate: candidate,
      base: base,
      baseSpec: baseSpec,
      result: result,
      isLoadingPublishedBase:
          isLoadingPublishedBase ?? this.isLoadingPublishedBase,
    );
  }

  @override
  List<Object?> get props => [
    candidate,
    base,
    baseSpec,
    result,
    isLoadingPublishedBase,
  ];
}
