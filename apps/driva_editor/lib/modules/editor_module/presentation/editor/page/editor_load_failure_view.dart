import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/contents_module/contents_module.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

enum _FailureTone { danger, warning }

typedef _FailureDisplay = ({
  String message,
  IconData icon,
  _FailureTone tone,
  String actionLabel,
  void Function(BuildContext) onAction,
});

/// Falha ao carregar o editor (D9, item 46): recebe [projectFuture] em vez de
/// refazer a busca — a tela já está em erro, duplicar a chamada de rede
/// dobraria o problema.
class EditorLoadFailureView extends StatelessWidget {
  const EditorLoadFailureView({
    required this.failure,
    required this.projectFuture,
    super.key,
  });

  final Failure failure;
  final Future<Either<Failure, Project>> projectFuture;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Scaffold(
      body: Center(
        // Espera o Future resolver (D6): sem isto a tela pisca "projeto não
        // existe" e volta atrás assim que a resposta chega.
        child: FutureBuilder<Either<Failure, Project>>(
          future: projectFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }

            final projectId = context.read<EditorCubit>().projectId;
            final display = _displayFor(snapshot.data, projectId);
            final tone = display.tone == _FailureTone.danger
                ? colors.danger
                : colors.warning;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(display.icon, size: AppIconSizes.s40, color: tone),
                const SizedBox(height: AppSpacing.s12),
                Text(display.message, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.s12),
                Semantics(
                  button: true,
                  label: display.actionLabel,
                  child: OutlinedButton(
                    onPressed: () => display.onAction(context),
                    child: Text(display.actionLabel),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  _FailureDisplay _displayFor(
    Either<Failure, Project>? projectResult,
    String projectId,
  ) => switch (failure) {
    NotFoundFailure() => _notFoundDisplayFor(projectResult, projectId),
    NetworkFailure() => (
      message: 'Sem conexão com o servidor. Tente de novo.',
      icon: Icons.wifi_off,
      tone: _FailureTone.warning,
      actionLabel: 'Voltar para o projeto',
      onAction: _backToProject(projectId),
    ),
    ConflictFailure(message: final m) => (
      message: m,
      icon: Icons.error_outline,
      tone: _FailureTone.danger,
      actionLabel: 'Voltar para o projeto',
      onAction: _backToProject(projectId),
    ),
    ValidationFailure(message: final m) => (
      message: 'Spec inválido: $m',
      icon: Icons.error_outline,
      tone: _FailureTone.danger,
      actionLabel: 'Voltar para o projeto',
      onAction: _backToProject(projectId),
    ),
    UnexpectedFailure() => (
      message: 'Algo deu errado ao abrir o editor.',
      icon: Icons.error_outline,
      tone: _FailureTone.danger,
      actionLabel: 'Voltar para o projeto',
      onAction: _backToProject(projectId),
    ),
  };

  /// Cruza o 404 do conteúdo com o [projectFuture] (D7): as três saídas não
  /// afirmam nada sobre existência em outro tenant — a rede caindo não vira
  /// "o projeto não existe".
  _FailureDisplay _notFoundDisplayFor(
    Either<Failure, Project>? projectResult,
    String projectId,
  ) => switch (projectResult) {
    Right(value: final project) => (
      message: 'Não encontramos este conteúdo no projeto "${project.title}".',
      icon: Icons.search_off,
      tone: _FailureTone.danger,
      actionLabel: 'Voltar para o projeto',
      onAction: _backToProject(projectId),
    ),
    Left(value: NotFoundFailure()) => (
      message: 'Este link aponta para um projeto que não existe.',
      icon: Icons.folder_off_outlined,
      tone: _FailureTone.danger,
      actionLabel: 'Ver meus projetos',
      onAction: _goToProjects,
    ),
    _ => (
      message: 'Não encontramos este conteúdo.',
      icon: Icons.cloud_off_outlined,
      tone: _FailureTone.warning,
      actionLabel: 'Ver meus projetos',
      onAction: _goToProjects,
    ),
  };

  void Function(BuildContext) _backToProject(String projectId) =>
      (context) => context.goNamed(
        ContentsRoutes.projectDetailName,
        pathParameters: {'id': projectId},
      );

  static void _goToProjects(BuildContext context) =>
      context.goNamed(ProjectsRoutes.projectsName);
}
