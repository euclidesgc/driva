import 'package:bloc/bloc.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:equatable/equatable.dart';

part 'version_history_state.dart';

/// Escopado ao diálogo (não ao `EditorCubit`, plan.md P4): carregar o
/// histórico paginado não pode reconstruir o canvas. Restaurar não mora
/// aqui — quem troca o documento é sempre o `EditorCubit`.
class VersionHistoryCubit extends Cubit<VersionHistoryState> {
  VersionHistoryCubit({
    required this.getContentVersionsUseCase,
    required this.contentId,
    int? publishedVersion,
  }) : _publishedVersion = publishedVersion,
       super(const VersionHistoryLoading());

  final GetContentVersionsUseCase getContentVersionsUseCase;
  final String contentId;
  final int? _publishedVersion;

  Future<void> load() async {
    emit(const VersionHistoryLoading());
    final result = await getContentVersionsUseCase(contentId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(VersionHistoryLoadFailure(failure: failure)),
      (page) => emit(
        VersionHistoryLoaded(
          versions: page.items,
          publishedVersion: _publishedVersion,
          nextCursor: page.nextCursor,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! VersionHistoryLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));

    final result = await getContentVersionsUseCase(
      contentId,
      cursor: current.nextCursor,
    );
    if (isClosed) return;
    final latest = state;
    if (latest is! VersionHistoryLoaded) return;

    result.fold(
      (failure) => emit(latest.copyWith(isLoadingMore: false)),
      (page) => emit(
        latest.copyWith(
          versions: [...latest.versions, ...page.items],
          nextCursor: () => page.nextCursor,
          isLoadingMore: false,
        ),
      ),
    );
  }
}
