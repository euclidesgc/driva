import 'dart:async';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/modules/contents_module/contents_module.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_history_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/publish/publish_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/publish/save_checkpoint_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/publish/unpublish_confirm_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_history_dialog.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:sdui_core/sdui_core.dart' show DiagnosticSeverity;
import 'package:sdui_flutter/sdui_flutter.dart';

class EditorTopRegistrar extends StatelessWidget {
  const EditorTopRegistrar({
    required this.projectFuture,
    required this.child,
    this.getContentVersionsUseCase,
    this.getContentVersionUseCase,
    this.getContentCheckpointsUseCase,
    this.imageUrlResolver,
    super.key,
  });

  final Future<Either<Failure, Project>> projectFuture;
  final Widget child;

  /// `null` só em teste sem DI (mesmo motivo de `EditorPage`, D19) — nesse
  /// caso o botão "Histórico" fica desabilitado, o resto do topo continua
  /// funcionando.
  final GetContentVersionsUseCase? getContentVersionsUseCase;

  /// Repassado a `VersionHistoryDialog` (T3, item 50) para o `Ver`/`Carregar
  /// no rascunho` de cada linha — mesma opcionalidade de
  /// [getContentVersionsUseCase].
  final GetContentVersionUseCase? getContentVersionUseCase;
  final GetContentCheckpointsUseCase? getContentCheckpointsUseCase;

  /// Repassado ao snapshot de `VersionReviewDialog` (T3, item 50) — mesmo
  /// resolvedor de imagens do canvas principal, para o preview histórico não
  /// quebrar imagem nenhuma.
  final SduiImageUrlResolver? imageUrlResolver;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    // D7: alcança o `EditorLayoutController` pelo soquete, não por um sexto
    // parâmetro de construtor a partir de `EditorWorkspace` (`VR-16-02`).
    final layoutController = EditorLayoutScope.of(context)!;
    return FutureBuilder<Either<Failure, Project>>(
      future: projectFuture,
      builder: (context, snapshot) {
        final projectTitle = switch (snapshot.data) {
          Right(value: final project) => project.title,
          _ => 'Projeto',
        };
        return BlocSelector<
          EditorCubit,
          EditorState,
          (
            String,
            SaveStatus,
            bool,
            bool,
            PublishBlockReason?,
            PublicationState,
          )
        >(
          selector: (state) => state is EditorReady
              ? (
                  state.document.name,
                  state.saveStatus,
                  state.canUndo,
                  state.canRedo,
                  state.publishBlockReason,
                  state.publication,
                )
              : (
                  '',
                  SaveStatus.saved,
                  false,
                  false,
                  PublishBlockReason.documentErrors,
                  const PublicationState(hasUnpublishedChanges: true),
                ),
          builder: (context, vm) {
            final (
              contentName,
              status,
              canUndo,
              canRedo,
              publishBlockReason,
              publication,
            ) = vm;
            final canPublish = publishBlockReason == null;
            return ValueListenableBuilder<bool>(
              valueListenable: layoutController.isFullscreen,
              builder: (context, isFullscreen, staticChild) => AppShellSlot(
                crumbs: [
                  const Crumb(
                    label: 'Projetos',
                    routeName: ProjectsRoutes.projectsName,
                  ),
                  Crumb(
                    label: projectTitle,
                    routeName: ContentsRoutes.projectDetailName,
                    pathParameters: {'id': cubit.projectId},
                  ),
                  Crumb(label: contentName),
                ],
                status: _statusFor(status, publication),
                immersive: isFullscreen,
                actions: [
                  AppBarAction.icon(
                    icon: Icons.undo,
                    tooltip: 'Desfazer (Ctrl+Z)',
                    onPressed: canUndo ? cubit.undo : null,
                  ),
                  AppBarAction.icon(
                    icon: Icons.redo,
                    tooltip: 'Refazer (Ctrl+Shift+Z)',
                    onPressed: canRedo ? cubit.redo : null,
                  ),
                  AppBarAction.filled(
                    label: 'Salvar',
                    icon: Icons.save_outlined,
                    onPressed: status == SaveStatus.saving ? null : cubit.save,
                  ),
                  AppBarAction.icon(
                    icon: Icons.bookmark_add_outlined,
                    tooltip: 'Salvar e marcar no histórico',
                    onPressed: status == SaveStatus.saving
                        ? null
                        : () => _saveWithCheckpoint(context, cubit),
                  ),
                  AppBarAction.outlined(
                    label: 'Publicar',
                    tooltip: _publishTooltip(publishBlockReason),
                    onPressed: canPublish
                        ? () => _confirmPublish(context, cubit, publication)
                        : null,
                  ),
                  AppBarAction.icon(
                    icon: Icons.visibility_off_outlined,
                    tooltip: _unpublishTooltip(publication),
                    onPressed: publication.isPublished
                        ? () => _confirmUnpublish(context, cubit, publication)
                        : null,
                  ),
                  AppBarAction.outlined(
                    label: 'Histórico',
                    icon: Icons.history,
                    tooltip: _historyTooltip(
                      getContentVersionsUseCase,
                      getContentVersionUseCase,
                    ),
                    onPressed:
                        getContentVersionsUseCase == null ||
                            getContentVersionUseCase == null
                        ? null
                        : () => _openVersionHistory(
                            context,
                            cubit,
                            getContentVersionsUseCase,
                            getContentVersionUseCase,
                            getContentCheckpointsUseCase,
                            imageUrlResolver,
                          ),
                  ),
                ],
                child: staticChild!,
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}

Future<void> _confirmPublish(
  BuildContext context,
  EditorCubit cubit,
  PublicationState publication,
) async {
  final state = cubit.state;
  final warningsCount = state is EditorReady
      ? state.diagnostics
            .where((d) => d.severity == DiagnosticSeverity.warning)
            .length
      : 0;

  final result = await showDialog<PublishDialogResult>(
    context: context,
    builder: (_) =>
        PublishDialog(publication: publication, warningsCount: warningsCount),
  );
  if (result == null) return;
  await cubit.publish(note: result.note);
}

Future<void> _confirmUnpublish(
  BuildContext context,
  EditorCubit cubit,
  PublicationState publication,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) =>
        UnpublishConfirmDialog(versionsCount: publication.latestVersion ?? 0),
  );
  if (confirmed != true) return;
  await cubit.unpublish();
}

Future<void> _openVersionHistory(
  BuildContext context,
  EditorCubit cubit,
  GetContentVersionsUseCase? getContentVersionsUseCase,
  GetContentVersionUseCase? getContentVersionUseCase,
  GetContentCheckpointsUseCase? getContentCheckpointsUseCase,
  SduiImageUrlResolver? imageUrlResolver,
) async {
  if (getContentVersionsUseCase == null || getContentVersionUseCase == null) {
    return;
  }
  final state = cubit.state;
  if (state is! EditorReady) return;

  final historyCubit = VersionHistoryCubit(
    getContentVersionsUseCase: getContentVersionsUseCase,
    contentId: state.document.id,
    getContentCheckpointsUseCase: getContentCheckpointsUseCase,
    publishedVersion: state.publication.publishedVersion,
  );
  unawaited(historyCubit.load());

  await showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: historyCubit,
      child: VersionHistoryDialog(
        editorCubit: cubit,
        getContentVersionUseCase: getContentVersionUseCase,
        imageUrlResolver: imageUrlResolver,
      ),
    ),
  );
  await historyCubit.close();
}

/// Salvar marcando um ponto no histórico — o "commit" do editor. Fica ao lado
/// do Salvar, e não dentro dele, porque salvar é a ação de todo dia e não pode
/// ganhar um passo a mais: quem quer marcar sabe que quer.
Future<void> _saveWithCheckpoint(
  BuildContext context,
  EditorCubit cubit,
) async {
  final note = await showDialog<String>(
    context: context,
    builder: (_) => const SaveCheckpointDialog(),
  );
  if (note == null || !context.mounted) return;
  await cubit.save(checkpointNote: note);
}

/// O motivo do botão desabilitado tem que ser verdadeiro (acessibilidade):
/// "corrija os erros" só quando o bloqueio é mesmo por erro no documento.
String _publishTooltip(PublishBlockReason? reason) => switch (reason) {
  null => 'Publicar as alterações',
  PublishBlockReason.saving => 'Salvando…',
  PublishBlockReason.publishing => 'Publicando…',
  PublishBlockReason.documentErrors =>
    'Corrija os erros do documento antes de publicar '
        '(veja a barra de status)',
};

String _unpublishTooltip(PublicationState publication) {
  if (publication.isPublished) return 'Despublicar';
  if (!publication.everPublished) return 'Despublicar (nunca foi publicado)';
  return 'Despublicar (já está fora do ar)';
}

String _historyTooltip(
  GetContentVersionsUseCase? getContentVersionsUseCase,
  GetContentVersionUseCase? getContentVersionUseCase,
) {
  if (getContentVersionsUseCase == null || getContentVersionUseCase == null) {
    return 'Histórico de versões (indisponível)';
  }
  return 'Histórico de versões';
}

/// Estado da linha inteira do save é urgente e transiente — cobre a barra
/// enquanto dura. Quando não há nada em andamento, o status conta o que
/// importa depois de fechar a aba: o que está no ar.
AppBarStatus _statusFor(SaveStatus status, PublicationState publication) {
  if (status == SaveStatus.saving) {
    return const AppBarStatus(
      icon: Icons.sync,
      label: 'Salvando…',
      tone: AppBarStatusTone.neutral,
    );
  }
  if (status == SaveStatus.saveFailed) {
    return const AppBarStatus(
      icon: Icons.error_outline,
      label: 'Falha ao salvar',
      tone: AppBarStatusTone.danger,
    );
  }
  if (!publication.everPublished) {
    return const AppBarStatus(
      icon: Icons.visibility_off_outlined,
      label: 'Nunca publicado',
      tone: AppBarStatusTone.neutral,
    );
  }
  if (!publication.isPublished) {
    return AppBarStatus(
      icon: Icons.unpublished_outlined,
      label: 'Fora do ar (última: v${publication.latestVersion})',
      tone: AppBarStatusTone.danger,
    );
  }
  if (publication.hasUnpublishedChanges) {
    return AppBarStatus(
      icon: Icons.edit_outlined,
      label:
          'Alterações não publicadas (no ar: v${publication.publishedVersion})',
      tone: AppBarStatusTone.neutral,
    );
  }
  return AppBarStatus(
    icon: Icons.check_circle,
    label: 'No ar (v${publication.publishedVersion})',
    tone: AppBarStatusTone.success,
  );
}
