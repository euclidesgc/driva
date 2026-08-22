import 'package:bloc/bloc.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_review_target.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

part 'version_review_state.dart';

/// Escopado à revisão de uma única entrada (uma instância por seleção, mesmo
/// padrão do `VersionHistoryCubit`): nunca referencia `EditorCubit` nem o
/// documento do editor, e ler aqui não reconstrói o canvas principal.
class VersionReviewCubit extends Cubit<VersionReviewState> {
  VersionReviewCubit({
    required this.getContentVersionUseCase,
    required this.contentId,
    required this.target,
    this.getContentCheckpointUseCase,
  }) : super(const VersionReviewLoading());

  final GetContentVersionUseCase getContentVersionUseCase;

  /// Ausente, um [CheckpointTarget] falha ao carregar — a revisão de
  /// checkpoint é opcional pelo mesmo motivo dos outros use cases da T3
  /// (item 50/53).
  final GetContentCheckpointUseCase? getContentCheckpointUseCase;
  final String contentId;
  final VersionReviewTarget target;

  Future<void> load() async {
    emit(const VersionReviewLoading());
    final result = await _fetch();
    if (isClosed) return;
    result.fold(
      (failure) => emit(VersionReviewLoadFailure(failure: failure)),
      (loaded) => emit(VersionReviewLoaded(entry: loaded)),
    );
  }

  Future<Either<Failure, LoadedHistoryEntry>> _fetch() {
    final currentTarget = target;
    return switch (currentTarget) {
      PublishedVersionTarget(:final version) => getContentVersionUseCase(
        contentId,
        version,
      ).then((result) => result.map<LoadedHistoryEntry>((loaded) => loaded)),
      CheckpointTarget(:final checkpointId) => _fetchCheckpoint(checkpointId),
    };
  }

  Future<Either<Failure, LoadedHistoryEntry>> _fetchCheckpoint(
    String checkpointId,
  ) async {
    final checkpointUseCase = getContentCheckpointUseCase;
    if (checkpointUseCase == null) return const Left(UnexpectedFailure());
    final result = await checkpointUseCase(contentId, checkpointId);
    return result.map<LoadedHistoryEntry>((loaded) => loaded);
  }
}
