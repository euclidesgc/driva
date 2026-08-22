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
/// congela o rascunho enquanto o modo está aberto e quem o muta quando a
/// candidata inteira é aplicada, as duas únicas saídas do modo.
class VersionCompareModeCubit extends Cubit<VersionCompareModeState> {
  VersionCompareModeCubit({
    required this.getContentVersionUseCase,
    required this.getContentVersionsUseCase,
    required this.editorCubit,
    this.getContentCheckpointUseCase,
    this.getContentCheckpointsUseCase,
  }) : super(const VersionCompareModeInactive()) {
    _editorSubscription = editorCubit.stream.listen(_onEditorStateChanged);
  }

  final GetContentVersionUseCase getContentVersionUseCase;
  final GetContentVersionsUseCase getContentVersionsUseCase;

  /// Ausentes, comparar um ponto salvo simplesmente não é oferecido:
  /// [enterCheckpoint]/[selectCheckpoint] não fazem nada, e a linha do tempo
  /// navegada por [stepOlder]/[stepNewer] só enxerga publicações.
  final GetContentCheckpointUseCase? getContentCheckpointUseCase;
  final GetContentCheckpointsUseCase? getContentCheckpointsUseCase;
  final EditorCubit editorCubit;

  late final StreamSubscription<EditorState> _editorSubscription;

  Future<void> enter(int candidateVersion) => _enter(
    loadingState: () =>
        VersionCompareModeLoading(candidateVersion: candidateVersion),
    loadCandidate: (contentId) => getContentVersionUseCase(
      contentId,
      candidateVersion,
    ).then((result) => result.map<LoadedHistoryEntry>((loaded) => loaded)),
    failureState: (failure) => VersionCompareModeFailure(
      failure: failure,
      candidateVersion: candidateVersion,
    ),
  );

  /// Espelha [enter] para um ponto salvo — sem [getContentCheckpointUseCase]
  /// não há como buscar o spec dele, então a entrada no modo é um no-op.
  Future<void> enterCheckpoint(String checkpointId) {
    final checkpointUseCase = getContentCheckpointUseCase;
    if (checkpointUseCase == null) return Future<void>.value();
    return _enter(
      loadingState: () =>
          VersionCompareModeLoading(candidateCheckpointId: checkpointId),
      loadCandidate: (contentId) => checkpointUseCase(
        contentId,
        checkpointId,
      ).then((result) => result.map<LoadedHistoryEntry>((loaded) => loaded)),
      failureState: (failure) => VersionCompareModeFailure(
        failure: failure,
        candidateCheckpointId: checkpointId,
      ),
    );
  }

  Future<void> _enter({
    required VersionCompareModeState Function() loadingState,
    required Future<Either<Failure, LoadedHistoryEntry>> Function(
      String contentId,
    )
    loadCandidate,
    required VersionCompareModeState Function(Failure failure) failureState,
  }) async {
    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;
    emit(loadingState());

    final contentId = editorState.document.id;
    final candidateFuture = loadCandidate(contentId);
    final versionsFuture = getContentVersionsUseCase(contentId);
    final checkpointsFuture = getContentCheckpointsUseCase?.call(contentId);

    final candidateResult = await candidateFuture;
    if (isClosed) return;

    LoadedHistoryEntry? candidate;
    candidateResult.fold(
      (failure) => emit(failureState(failure)),
      (loaded) => candidate = loaded,
    );
    final loadedCandidate = candidate;
    if (loadedCandidate == null) return;

    final versionsResult = await versionsFuture;
    final checkpointsResult = await checkpointsFuture;
    if (isClosed) return;
    final latestEditorState = editorCubit.state;
    if (latestEditorState is! EditorReady) return;

    final versionsPage = versionsResult.getOrElse(
      (_) => const ContentVersionsPage(items: []),
    );
    final checkpointsPage =
        checkpointsResult?.getOrElse(
          (_) => const ContentCheckpointsPage(items: []),
        ) ??
        const ContentCheckpointsPage(items: []);

    editorCubit.setReadOnly(value: true);
    emit(
      VersionCompareModeActive(
        candidate: loadedCandidate,
        baseSpec: latestEditorState.document,
        result: compareContentSpecs(
          latestEditorState.document,
          loadedCandidate.spec,
        ),
        versions: versionsPage.items,
        checkpoints: checkpointsPage.items,
        nextCursor: versionsPage.nextCursor,
        checkpointsCursor: checkpointsPage.nextCursor,
      ),
    );
  }

  /// Chamada pelo `Histórico` da top bar continuando vivo durante o modo
  /// (D2): troca a candidata em vez de abrir um segundo modo.
  Future<void> selectVersion(int version) => _select(
    isCurrent: (candidate) =>
        candidate is LoadedContentVersion && candidate.version == version,
    load: (contentId) => getContentVersionUseCase(
      contentId,
      version,
    ).then((result) => result.map<LoadedHistoryEntry>((loaded) => loaded)),
    failureState: (failure) =>
        VersionCompareModeFailure(failure: failure, candidateVersion: version),
  );

  /// Espelha [selectVersion] para um ponto salvo.
  Future<void> selectCheckpoint(String checkpointId) {
    final checkpointUseCase = getContentCheckpointUseCase;
    if (checkpointUseCase == null) return Future<void>.value();
    return _select(
      isCurrent: (candidate) =>
          candidate is LoadedContentCheckpoint && candidate.id == checkpointId,
      load: (contentId) => checkpointUseCase(
        contentId,
        checkpointId,
      ).then((result) => result.map<LoadedHistoryEntry>((loaded) => loaded)),
      failureState: (failure) => VersionCompareModeFailure(
        failure: failure,
        candidateCheckpointId: checkpointId,
      ),
    );
  }

  Future<void> _select({
    required bool Function(LoadedHistoryEntry candidate) isCurrent,
    required Future<Either<Failure, LoadedHistoryEntry>> Function(
      String contentId,
    )
    load,
    required VersionCompareModeState Function(Failure failure) failureState,
  }) async {
    final current = state;
    if (current is! VersionCompareModeActive) return;
    if (isCurrent(current.candidate)) return;
    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;

    final result = await load(editorState.document.id);
    if (isClosed) return;
    final latest = state;
    if (latest is! VersionCompareModeActive) return;

    result.fold(
      (failure) => emit(failureState(failure)),
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

  Future<void> _selectEntry(ContentHistoryEntry entry) => switch (entry) {
    PublishedVersionEntry(version: final v) => selectVersion(v.version),
    CheckpointEntry(checkpoint: final c) => selectCheckpoint(c.id),
  };

  /// `‹`/`›` da barra da candidata (D2, item 53): navegam pela linha do
  /// tempo mesclada em `VersionCompareModeActive.entries` (mais nova no
  /// índice 0, mais antiga crescendo o índice) — publicação e ponto salvo
  /// intercalados, exatamente como o histórico mostra. Nas pontas — mais
  /// nova em [stepNewer], mais antiga já carregada e sem cursor nenhum em
  /// [stepOlder] — não emitem: não há para onde ir.
  Future<void> stepOlder() async {
    final current = state;
    if (current is! VersionCompareModeActive) return;
    final index = current._candidateIndex;
    if (index < 0) return;

    if (index < current.entries.length - 1) {
      await _selectEntry(current.entries[index + 1]);
      return;
    }
    if (!current.hasMoreHistory || current.isLoadingMore) return;

    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return;

    emit(current.copyWith(isLoadingMore: true));
    final contentId = editorState.document.id;
    final versionsFuture = current.nextCursor == null
        ? null
        : getContentVersionsUseCase(contentId, cursor: current.nextCursor);
    final checkpointsFuture = current.checkpointsCursor == null
        ? null
        : getContentCheckpointsUseCase?.call(
            contentId,
            cursor: current.checkpointsCursor,
          );
    final versionsResult = await versionsFuture;
    final checkpointsResult = await checkpointsFuture;
    if (isClosed) return;
    final latest = state;
    if (latest is! VersionCompareModeActive) return;

    final moreVersions = versionsResult?.getRight().toNullable();
    final moreCheckpoints = checkpointsResult?.getRight().toNullable();

    emit(
      latest.copyWith(
        versions: [...latest.versions, ...?moreVersions?.items],
        checkpoints: [...latest.checkpoints, ...?moreCheckpoints?.items],
        nextCursor: () => versionsFuture == null || moreVersions == null
            ? latest.nextCursor
            : moreVersions.nextCursor,
        checkpointsCursor: () =>
            checkpointsFuture == null || moreCheckpoints == null
            ? latest.checkpointsCursor
            : moreCheckpoints.nextCursor,
        isLoadingMore: false,
      ),
    );

    final refreshed = state;
    if (refreshed is! VersionCompareModeActive) return;
    final refreshedEntries = refreshed.entries;
    if (refreshedEntries.length > current.entries.length) {
      await _selectEntry(refreshedEntries[current.entries.length]);
    }
  }

  Future<void> stepNewer() async {
    final current = state;
    if (current is! VersionCompareModeActive) return;
    final index = current._candidateIndex;
    if (index <= 0) return;
    await _selectEntry(current.entries[index - 1]);
  }

  /// D6: deixa o rascunho idêntico à versão publicada, em memória — uma
  /// entrada de undo, nada persiste até o próximo `Salvar`. Quando a
  /// candidata em tela já é a publicada, o spec dela é reusado sem nova
  /// requisição. Encerra o modo pelo mesmo motivo de
  /// [applyCandidateToDraft]: é escrita no rascunho, e o modo não convive
  /// com rascunho mudando.
  Future<bool> returnToPublished() async {
    final editorState = editorCubit.state;
    if (editorState is! EditorReady) return false;
    final publishedVersion = editorState.publication.publishedVersion;
    if (publishedVersion == null) return false;

    final current = state;
    if (current is VersionCompareModeActive) {
      final candidate = current.candidate;
      if (candidate is LoadedContentVersion &&
          candidate.version == publishedVersion) {
        exit();
        editorCubit.loadVersionIntoDraft(
          candidate.spec,
          version: publishedVersion,
        );
        return true;
      }
    }

    final result = await getContentVersionUseCase(
      editorState.document.id,
      publishedVersion,
    );
    if (isClosed) return false;
    return result.fold((_) => false, (loaded) {
      exit();
      editorCubit.loadVersionIntoDraft(loaded.spec, version: publishedVersion);
      return true;
    });
  }

  /// A saída "aplica": traz a candidata inteira para o rascunho e encerra o
  /// modo — com os dois lados idênticos não sobra o que comparar. Sai antes
  /// de aplicar para o rascunho descongelar e o diff não ser recalculado
  /// contra um estado que morre na linha seguinte.
  void applyCandidateToDraft() {
    final current = state;
    if (current is! VersionCompareModeActive) return;
    final candidate = current.candidate;
    exit();
    editorCubit.loadVersionIntoDraft(
      candidate.spec,
      version: switch (candidate) {
        LoadedContentVersion(:final version) => version,
        LoadedContentCheckpoint() => null,
      },
    );
  }

  /// `Fechar comparação` é a saída limpa: o rascunho volta a ser editável
  /// exatamente como entrou, porque o modo não deixa editar nada enquanto
  /// está aberto — não há o que reverter.
  void exit() {
    editorCubit.setReadOnly(value: false);
    if (state is VersionCompareModeInactive) return;
    emit(const VersionCompareModeInactive());
  }

  void _onEditorStateChanged(EditorState editorState) {
    if (isClosed || editorState is! EditorReady) return;

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
