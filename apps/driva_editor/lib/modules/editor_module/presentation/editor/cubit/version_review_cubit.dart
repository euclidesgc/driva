import 'package:bloc/bloc.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:equatable/equatable.dart';

part 'version_review_state.dart';

/// Escopado à revisão de uma única versão (uma instância por seleção, mesmo
/// padrão do `VersionHistoryCubit`): nunca referencia `EditorCubit` nem o
/// documento do editor, e ler aqui não reconstrói o canvas principal.
class VersionReviewCubit extends Cubit<VersionReviewState> {
  VersionReviewCubit({
    required this.getContentVersionUseCase,
    required this.contentId,
    required this.version,
  }) : super(const VersionReviewLoading());

  final GetContentVersionUseCase getContentVersionUseCase;
  final String contentId;
  final int version;

  Future<void> load() async {
    emit(const VersionReviewLoading());
    final result = await getContentVersionUseCase(contentId, version);
    if (isClosed) return;
    result.fold(
      (failure) => emit(VersionReviewLoadFailure(failure: failure)),
      (loaded) => emit(VersionReviewLoaded(version: loaded)),
    );
  }
}
