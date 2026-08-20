import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_comparison_base.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

part 'version_compare_state.dart';

/// Compara uma versão histórica com o rascunho (ou, sob pedido, com a
/// versão no ar) e devolve cópias seletivas de propriedades ao
/// `EditorCubit` (T5, item 50). Ao contrário do `VersionReviewCubit`
/// (leitura pura, nunca referencia o editor), este cubit referencia
/// `EditorCubit` de propósito — é ele quem muta o rascunho quando a seta é
/// usada — e por isso acompanha o stream do editor para manter o lado
/// "rascunho" sincronizado enquanto o diálogo de comparação está aberto.
class VersionCompareCubit extends Cubit<VersionCompareState> {
  VersionCompareCubit({
    required this.getContentVersionUseCase,
    required this.editorCubit,
    required this.contentId,
    required this.candidateVersion,
  }) : publishedVersion = switch (editorCubit.state) {
         final EditorReady s => s.publication.publishedVersion,
         _ => null,
       },
       super(const VersionCompareLoading()) {
    _editorSubscription = editorCubit.stream.listen(_onEditorStateChanged);
  }

  final GetContentVersionUseCase getContentVersionUseCase;
  final EditorCubit editorCubit;
  final String contentId;
  final int candidateVersion;

  /// Capturada na abertura (mesmo padrão de `VersionHistoryCubit`): decide
  /// se o toggle "No ar" existe, sem reagir a um publish feito com o
  /// diálogo já aberto.
  final int? publishedVersion;

  late final StreamSubscription<EditorState> _editorSubscription;
  LoadedContentVersion? _publishedSnapshot;

  Future<void> load() async {
    emit(const VersionCompareLoading());
    final result = await getContentVersionUseCase(
      contentId,
      candidateVersion,
    );
    if (isClosed) return;
    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;
    result.fold(
      (failure) => emit(VersionCompareLoadFailure(failure: failure)),
      (candidate) => emit(_draftLoadedState(candidate, editorState.document)),
    );
  }

  Future<void> useBase(VersionComparisonBase base) async {
    final current = state;
    if (current is! VersionCompareLoaded || base == current.base) return;

    if (base == VersionComparisonBase.draft) {
      final editorState = editorCubit.state;
      if (editorState is! EditorReady) return;
      emit(_draftLoadedState(current.candidate, editorState.document));
      return;
    }

    final cached = _publishedSnapshot;
    if (cached != null) {
      emit(_publishedLoadedState(current.candidate, cached));
      return;
    }

    final version = publishedVersion;
    if (version == null) return;

    emit(current.copyWith(isLoadingPublishedBase: true));
    final result = await getContentVersionUseCase(contentId, version);
    if (isClosed) return;
    final latest = state;
    if (latest is! VersionCompareLoaded) return;

    result.fold(
      (failure) => emit(latest.copyWith(isLoadingPublishedBase: false)),
      (loaded) {
        _publishedSnapshot = loaded;
        emit(_publishedLoadedState(latest.candidate, loaded));
      },
    );
  }

  /// A cópia sempre incide sobre o rascunho de verdade
  /// (`editorCubit.state.document`), nunca sobre o que está sendo exibido
  /// como base — por isso ela é recusada quando a base exibida é a versão
  /// no ar; o toggle é só um jeito de olhar, não de escolher alvo.
  void copyNodeProperties(String nodeId) {
    final current = state;
    if (current is! VersionCompareLoaded ||
        current.base != VersionComparisonBase.draft) {
      return;
    }
    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;

    copyComparableNodeProperties(
      editorState.document,
      current.candidate.spec,
      nodeId,
    ).fold(
      // Só alcançável com um spec fora do contrato zard (dartdoc de
      // `NonStringPropertyKeyForCopyFailure`), nunca vindo de
      // `parseContentSpec` — inatingível pelo fluxo real deste diálogo.
      (failure) {},
      editorCubit.applyComparedNodeProperties,
    );
  }

  void _onEditorStateChanged(EditorState editorState) {
    if (isClosed || editorState is! EditorReady) return;
    final current = state;
    if (current is! VersionCompareLoaded ||
        current.base != VersionComparisonBase.draft ||
        identical(editorState.document, current.baseSpec)) {
      return;
    }
    emit(_draftLoadedState(current.candidate, editorState.document));
  }

  VersionCompareLoaded _draftLoadedState(
    LoadedContentVersion candidate,
    ContentSpec draftSpec,
  ) {
    return VersionCompareLoaded(
      candidate: candidate,
      base: VersionComparisonBase.draft,
      baseSpec: draftSpec,
      result: compareContentSpecs(draftSpec, candidate.spec),
    );
  }

  VersionCompareLoaded _publishedLoadedState(
    LoadedContentVersion candidate,
    LoadedContentVersion publishedSnapshot,
  ) {
    return VersionCompareLoaded(
      candidate: candidate,
      base: VersionComparisonBase.published,
      baseSpec: publishedSnapshot.spec,
      result: compareContentSpecs(publishedSnapshot.spec, candidate.spec),
    );
  }

  @override
  Future<void> close() {
    unawaited(_editorSubscription.cancel());
    return super.close();
  }
}
