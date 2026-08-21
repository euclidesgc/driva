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
/// versão inteira é aplicada, as duas únicas saídas do modo.
class VersionCompareModeCubit extends Cubit<VersionCompareModeState> {
  VersionCompareModeCubit({
    required this.getContentVersionUseCase,
    required this.getContentVersionsUseCase,
    required this.editorCubit,
  }) : super(const VersionCompareModeInactive()) {
    _editorSubscription = editorCubit.stream.listen(_onEditorStateChanged);
  }

  final GetContentVersionUseCase getContentVersionUseCase;
  final GetContentVersionsUseCase getContentVersionsUseCase;
  final EditorCubit editorCubit;

  late final StreamSubscription<EditorState> _editorSubscription;

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
    editorCubit.setReadOnly(value: true);
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
    if (current is VersionCompareModeActive &&
        current.candidate.version == publishedVersion) {
      exit();
      editorCubit.loadVersionIntoDraft(
        current.candidate.spec,
        version: publishedVersion,
      );
      return true;
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

  /// A saída "aplica": traz a versão comparada inteira para o rascunho e
  /// encerra o modo — com os dois lados idênticos não sobra o que comparar.
  /// Sai antes de aplicar para o rascunho descongelar e o diff não ser
  /// recalculado contra um estado que morre na linha seguinte.
  void applyCandidateToDraft() {
    final current = state;
    if (current is! VersionCompareModeActive) return;
    final candidate = current.candidate;
    exit();
    editorCubit.loadVersionIntoDraft(
      candidate.spec,
      version: candidate.version,
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
