import 'package:bloc/bloc.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart' show ContentSpec;

part 'preview_state.dart';

/// Busca o conteúdo pelo mesmo [LoadContentUseCase] do editor (D3, item 41):
/// a rota de preview não abre superfície de API nova. [contentId] fica fixo
/// no construtor porque o único gatilho de recarga (a pílula "último salvo",
/// D4) refaz a mesma busca, sem trocar de conteúdo.
class PreviewCubit extends Cubit<PreviewState> {
  PreviewCubit({required this.loadContentUseCase, required this.contentId})
    : super(const PreviewLoading());

  final LoadContentUseCase loadContentUseCase;
  final String contentId;

  Future<void> load() async {
    emit(const PreviewLoading());
    final result = await loadContentUseCase(contentId);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => PreviewFailure(failure: failure),
        (spec) => PreviewReady(spec: spec, fetchedAt: DateTime.now()),
      ),
    );
  }
}
