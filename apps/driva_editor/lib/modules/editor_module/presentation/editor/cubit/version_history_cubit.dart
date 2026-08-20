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
    this.getContentCheckpointsUseCase,
    int? publishedVersion,
  }) : _publishedVersion = publishedVersion,
       super(const VersionHistoryLoading());

  final GetContentVersionsUseCase getContentVersionsUseCase;

  /// Ausente, o histórico mostra só publicações. Opcional pelo mesmo motivo
  /// que os outros use cases de versão o são na página: montar o editor sem
  /// a feature precisa continuar possível.
  final GetContentCheckpointsUseCase? getContentCheckpointsUseCase;
  final String contentId;
  final int? _publishedVersion;

  Future<void> load() async {
    emit(const VersionHistoryLoading());
    final versionsFuture = getContentVersionsUseCase(contentId);
    final checkpointsFuture = getContentCheckpointsUseCase?.call(contentId);

    final versionsResult = await versionsFuture;
    final checkpointsResult = await checkpointsFuture;
    if (isClosed) return;

    final failure = versionsResult.getLeft().toNullable();
    if (failure != null) {
      emit(VersionHistoryLoadFailure(failure: failure));
      return;
    }
    final versions = versionsResult.getOrElse(
      (_) => const ContentVersionsPage(items: []),
    );
    // Falha só nos pontos marcados **não** derruba o histórico: as
    // publicações são o que o usuário mais precisa ver, e negá-las por causa
    // de uma lista acessória seria trocar informação por nada.
    final checkpoints =
        checkpointsResult?.getOrElse(
          (_) => const ContentCheckpointsPage(items: []),
        ) ??
        const ContentCheckpointsPage(items: []);

    emit(
      VersionHistoryLoaded(
        versions: versions.items,
        checkpoints: checkpoints.items,
        publishedVersion: _publishedVersion,
        nextCursor: versions.nextCursor,
        checkpointsCursor: checkpoints.nextCursor,
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

    // As duas fontes paginam por chaves diferentes — versão por número,
    // ponto marcado por data — então cada uma tem o próprio cursor e só é
    // pedida enquanto tiver mais. Mesclar depois mantém a ordem correta.
    final versionsPage = current.nextCursor == null
        ? null
        : await getContentVersionsUseCase(
            contentId,
            cursor: current.nextCursor,
          );
    final checkpointsPage = current.checkpointsCursor == null
        ? null
        : await getContentCheckpointsUseCase?.call(
            contentId,
            cursor: current.checkpointsCursor,
          );
    if (isClosed) return;
    final latest = state;
    if (latest is! VersionHistoryLoaded) return;

    // Falha ao paginar preserva o cursor: zerá-lo faria o histórico esquecer
    // que há mais para carregar, e o usuário perderia o resto do passado por
    // causa de uma requisição que pode ter falhado por rede.
    final moreVersions = versionsPage?.getRight().toNullable();
    final moreCheckpoints = checkpointsPage?.getRight().toNullable();

    emit(
      latest.copyWith(
        versions: [...latest.versions, ...?moreVersions?.items],
        checkpoints: [...latest.checkpoints, ...?moreCheckpoints?.items],
        nextCursor: () => versionsPage == null || moreVersions == null
            ? latest.nextCursor
            : moreVersions.nextCursor,
        checkpointsCursor: () =>
            checkpointsPage == null || moreCheckpoints == null
            ? latest.checkpointsCursor
            : moreCheckpoints.nextCursor,
        isLoadingMore: false,
      ),
    );
  }
}
