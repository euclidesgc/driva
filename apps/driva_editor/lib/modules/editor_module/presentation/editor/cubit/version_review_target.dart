import 'package:equatable/equatable.dart';

/// O que `VersionReviewCubit` busca: uma publicação (por número) ou um
/// checkpoint (por id) — as duas espécies do histórico que podem ser vistas
/// sem sair do modo de leitura.
sealed class VersionReviewTarget extends Equatable {
  const VersionReviewTarget();
}

final class PublishedVersionTarget extends VersionReviewTarget {
  const PublishedVersionTarget(this.version);

  final int version;

  @override
  List<Object?> get props => [version];
}

final class CheckpointTarget extends VersionReviewTarget {
  const CheckpointTarget(this.checkpointId);

  final String checkpointId;

  @override
  List<Object?> get props => [checkpointId];
}
