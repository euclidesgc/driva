import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

import '../../../../core/error/error.dart';
import '../../../../core/network/project_scope.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../injection.dart';
import '../../../contents_module/contents_module.dart';
import '../../../projects_module/projects_module.dart';
import '../../domain/use_cases/use_cases.dart';
import 'cubit/editor_cubit.dart';
import 'page/page.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key, required this.projectFuture});

  /// Busca do projeto em foco (para o crumb de nível 2) disparada pelo
  /// [pageBuilder]. Fallback para um label genérico se ainda não resolveu ou
  /// se o [ProjectScope] estiver vazio (deep link direto ao editor).
  final Future<Either<Failure, Project>> projectFuture;

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    final id = state.pathParameters['id'];
    // Deep link malformado não é crash, é tela tratada.
    if (id == null || id.trim().isEmpty) return const InvalidContentScreen();

    // O projeto em foco (setado pela tela do projeto ao abrir o conteúdo)
    // é o destino do "voltar"/crumb do editor.
    final projectId = getIt<ProjectScope>().projectId;

    return BlocProvider(
      create: (_) => EditorCubit(
        loadContentUseCase: getIt<LoadContentUseCase>(),
        saveDraftUseCase: getIt<SaveDraftUseCase>(),
        projectId: projectId,
      )..loadContent(id),
      child: EditorPage(projectFuture: getIt<GetProjectUseCase>()(projectId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A casca (Loading/Failure/Ready) só troca quando muda o TIPO do estado.
    // Enquanto o editor está pronto, cada painel reage à SUA fatia (selectors),
    // então digitar/arrastar não reconstrói o workspace inteiro.
    return BlocBuilder<EditorCubit, EditorState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      builder: (context, state) => switch (state) {
        EditorLoading() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        final EditorLoadFailure s => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_messageFor(s.failure)),
                const SizedBox(height: AppSpacing.s12),
                OutlinedButton(
                  onPressed: () => context.goNamed(
                    ContentsRoutes.projectDetailName,
                    pathParameters: {
                      'id': context.read<EditorCubit>().projectId,
                    },
                  ),
                  child: const Text('Voltar para o projeto'),
                ),
              ],
            ),
          ),
        ),
        EditorReady() => EditorWorkspace(projectFuture: projectFuture),
      },
    );
  }

  String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
    NotFoundFailure() => 'Conteúdo não encontrado.',
    ConflictFailure(message: final m) => m,
    ValidationFailure(message: final m) => 'Spec inválido: $m',
    UnexpectedFailure() => 'Algo deu errado ao abrir o editor.',
  };
}
