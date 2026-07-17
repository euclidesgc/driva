import 'dart:async';

import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/network/project_scope.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/injection.dart';
import 'package:driva_editor/modules/contents_module/contents_module.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/page.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({required this.projectFuture, super.key});

  final Future<Either<Failure, Project>> projectFuture;

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    final id = state.pathParameters['id'];

    if (id == null || id.trim().isEmpty) return const InvalidContentScreen();

    final projectId = getIt<ProjectScope>().projectId;

    return BlocProvider(
      create: (_) {
        final cubit = EditorCubit(
          loadContentUseCase: getIt<LoadContentUseCase>(),
          saveDraftUseCase: getIt<SaveDraftUseCase>(),
          projectId: projectId,
        );
        unawaited(cubit.loadContent(id));
        return cubit;
      },
      child: EditorPage(projectFuture: getIt<GetProjectUseCase>()(projectId)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
