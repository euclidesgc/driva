import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

part 'version_compare_mode_state.dart';

/// A comparação é um **modo do editor** (plan_t5b, D1/D3), não mais um
/// diálogo: escopado à página, criado uma vez acima de `EditorWorkspace` e
/// vivo enquanto ela vive. Referencia `EditorCubit` de propósito — é quem
/// muta o rascunho quando uma propriedade é trazida da candidata — e por
/// isso acompanha `editorCubit.stream` para manter `baseSpec` igual ao
/// rascunho ao vivo enquanto o modo está ativo.
class VersionCompareModeCubit extends Cubit<VersionCompareModeState> {
  VersionCompareModeCubit({
    required this.getContentVersionUseCase,
    required this.getContentVersionsUseCase,
    required this.editorCubit,
  }) : _lastSaveStatus = switch (editorCubit.state) {
         final EditorReady s => s.saveStatus,
         _ => null,
       },
       super(const VersionCompareModeInactive()) {
    _editorSubscription = editorCubit.stream.listen(_onEditorStateChanged);
  }

  final GetContentVersionUseCase getContentVersionUseCase;
  final GetContentVersionsUseCase getContentVersionsUseCase;
  final EditorCubit editorCubit;

  late final StreamSubscription<EditorState> _editorSubscription;

  /// Rastreado à parte porque o stream do editor entrega um estado por vez,
  /// nunca o par (anterior, atual) — e a saída por salvamento depende da
  /// **transição** `saving → saved` (D3), não do estado `saved` isolado: um
  /// `Ctrl+Z` que devolva o documento ao último salvo também emite `saved`
  /// e não pode fechar o modo.
  SaveStatus? _lastSaveStatus;

  Future<void> enter(int candidateVersion) async {
    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;
    emit(VersionCompareModeLoading(candidateVersion: candidateVersion));

    final contentId = editorState.document.id;
    final candidateFuture = getContentVersionUseCase(
      contentId,
      candidateVersion,
    );
    final versionsFuture = getContentVersionsUseCase(contentId);

    final candidateResult = await candidateFuture;
    if (isClosed) return;

    LoadedContentVersion? candidate;
    candidateResult.fold(
      (failure) => emit(
        VersionCompareModeFailure(
          failure: failure,
          candidateVersion: candidateVersion,
        ),
      ),
      (loaded) => candidate = loaded,
    );
    final loadedCandidate = candidate;
    if (loadedCandidate == null) return;

    final versionsResult = await versionsFuture;
    if (isClosed) return;
    final latestEditorState = editorCubit.state;
    if (latestEditorState is! EditorReady) return;

    final page = versionsResult.fold(
      (_) => const ContentVersionsPage(items: []),
      (loadedPage) => loadedPage,
    );
    emit(
      VersionCompareModeActive(
        candidate: loadedCandidate,
        baseSpec: latestEditorState.document,
        result: compareContentSpecs(
          latestEditorState.document,
          loadedCandidate.spec,
        ),
        versions: page.items,
        nextCursor: page.nextCursor,
      ),
    );
  }

  /// Chamada pelo `Histórico` da top bar continuando vivo durante o modo
  /// (D2): troca a candidata em vez de abrir um segundo modo.
  Future<void> selectVersion(int version) async {
    final current = state;
    if (current is! VersionCompareModeActive) return;
    if (version == current.candidate.version) return;
    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;

    final result = await getContentVersionUseCase(
      editorState.document.id,
      version,
    );
    if (isClosed) return;
    final latest = state;
    if (latest is! VersionCompareModeActive) return;

    result.fold(
      (failure) => emit(
        VersionCompareModeFailure(failure: failure, candidateVersion: version),
      ),
      (candidate) {
        final latestEditorState = editorCubit.state;
        if (latestEditorState is! EditorReady) return;
        emit(
          latest.copyWith(
            candidate: candidate,
            baseSpec: latestEditorState.document,
            result: compareContentSpecs(
              latestEditorState.document,
              candidate.spec,
            ),
          ),
        );
      },
    );
  }

  /// `‹`/`›` da barra da candidata (D2): navegam pela lista já paginada em
  /// `VersionCompareModeActive.versions` (mais nova no índice 0, mais
  /// antiga crescendo o índice). Nas pontas — mais nova em [stepNewer], mais
  /// antiga já carregada e sem `nextCursor` em [stepOlder] — não emitem: não
  /// há para onde ir.
  Future<void> stepOlder() async {
    final current = state;
    if (current is! VersionCompareModeActive) return;
    final index = _indexOfCandidate(current);
    if (index < 0) return;

    if (index < current.versions.length - 1) {
      await selectVersion(current.versions[index + 1].version);
      return;
    }
    if (current.nextCursor == null || current.isLoadingMore) return;

    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;

    emit(current.copyWith(isLoadingMore: true));
    final result = await getContentVersionsUseCase(
      editorState.document.id,
      cursor: current.nextCursor,
    );
    if (isClosed) return;
    final latest = state;
    if (latest is! VersionCompareModeActive) return;

    await result.fold(
      (failure) async => emit(latest.copyWith(isLoadingMore: false)),
      (page) async {
        emit(
          latest.copyWith(
            versions: [...latest.versions, ...page.items],
            nextCursor: () => page.nextCursor,
            isLoadingMore: false,
          ),
        );
        if (page.items.isNotEmpty) {
          await selectVersion(page.items.first.version);
        }
      },
    );
  }

  Future<void> stepNewer() async {
    final current = state;
    if (current is! VersionCompareModeActive) return;
    final index = _indexOfCandidate(current);
    if (index <= 0) return;
    await selectVersion(current.versions[index - 1].version);
  }

  int _indexOfCandidate(VersionCompareModeActive current) =>
      current.versions.indexWhere(
        (each) => each.version == current.candidate.version,
      );

  /// A cópia sempre incide sobre o rascunho de verdade
  /// (`editorCubit.state.document`): neste modo ele **é** `baseSpec`, os
  /// dois nunca divergem (D5 — não há mais "base publicada" para trocar).
  void copyNodeProperties(String nodeId) {
    final current = state;
    if (current is! VersionCompareModeActive) return;
    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;

    copyComparableNodeProperties(
      editorState.document,
      current.candidate.spec,
      nodeId,
    ).fold(
      // Só alcançável com um spec fora do contrato zard (dartdoc de
      // `NonStringPropertyKeyForCopyFailure`), nunca vindo de
      // `parseContentSpec` — inatingível pelo fluxo real deste modo.
      (failure) {},
      editorCubit.applyComparedNodeProperties,
    );
  }

  /// D3: `Fechar comparação` só fecha, nada é revertido por baixo dos
  /// panos — o que foi copiado continua no rascunho, desfazível um a um por
  /// `Ctrl+Z` como qualquer edição manual.
  void exit() {
    if (state is VersionCompareModeInactive) return;
    emit(const VersionCompareModeInactive());
  }

  void _onEditorStateChanged(EditorState editorState) {
    if (isClosed || editorState is! EditorReady) return;

    final previousStatus = _lastSaveStatus;
    _lastSaveStatus = editorState.saveStatus;

    if (previousStatus == SaveStatus.saving &&
        editorState.saveStatus == SaveStatus.saved) {
      exit();
      return;
    }

    final current = state;
    if (current is! VersionCompareModeActive ||
        identical(editorState.document, current.baseSpec)) {
      return;
    }
    emit(
      current.copyWith(
        baseSpec: editorState.document,
        result: compareContentSpecs(
          editorState.document,
          current.candidate.spec,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    unawaited(_editorSubscription.cancel());
    return super.close();
  }
}
