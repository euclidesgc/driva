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
        (loaded) => PreviewReady(spec: loaded.spec, fetchedAt: DateTime.now()),
      ),
    );
  }

  /// Não reusa [load]: emitir `PreviewLoading` apagaria o conteúdo em tela
  /// enquanto busca de novo, o que a D30 proíbe. Falha reemite o
  /// [PreviewReady] anterior com o sinal de erro à parte, sem tocar no
  /// carimbo.
  Future<void> refresh() async {
    final current = state;
    if (current is! PreviewReady) return;
    final result = await loadContentUseCase(contentId);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => current.copyWith(refreshFailure: failure),
        (loaded) => PreviewReady(spec: loaded.spec, fetchedAt: DateTime.now()),
      ),
    );
  }
}
