import 'dart:async';

import 'package:driva_editor/core/config/app_config.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/network/network.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/injection.dart';
import 'package:driva_editor/modules/contents_module/contents_module.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/page.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

const _editorBootScaffold = Scaffold(
  body: Center(child: CircularProgressIndicator()),
);

class EditorPage extends StatefulWidget {
  const EditorPage({
    required this.projectFuture,
    this.imageUrlResolver,
    this.contentId = '',
    this.layoutController,
    this.getEditorLayoutUseCase,
    this.saveEditorLayoutUseCase,
    super.key,
  });

  final Future<Either<Failure, Project>> projectFuture;

  /// Só o `pageBuilder` toca o `get_it` para montá-lo (regra do projeto);
  /// aqui ele só é repassado adiante.
  final SduiImageUrlResolver? imageUrlResolver;

  /// `id` da rota (`/contents/:id/edit`), repassado ao [EditorViewportGate]
  /// para o botão "Ver conteúdo" (D24) — o mesmo `id`, não o do documento já
  /// carregado, porque o portão decide antes de o `EditorCubit` ter estado.
  /// Opcional (D19): `editor_perf_test.dart` e `canvas_panel_golden_test.dart`
  /// montam `EditorPage` sem DI e sempre em largura acima de `compact`.
  final String contentId;

  /// Opcional (D19): ausente, a página cria e possui um controller em
  /// memória com os padrões — o mesmo motivo do [contentId] opcional, para
  /// que os dois testes acima continuem montando `EditorPage` sem DI.
  final EditorLayoutController? layoutController;

  /// Repassados ao controller que `_EditorPageState` cria quando
  /// [layoutController] está ausente (F6). `pageBuilder` os resolve do
  /// `get_it` — continua sendo o único lugar que toca o container — e esta
  /// página só os encaminha, como já faz com [imageUrlResolver]. `null`
  /// mantém o controller só em memória, sem persistência (D19).
  final GetEditorLayoutUseCase? getEditorLayoutUseCase;
  final SaveEditorLayoutUseCase? saveEditorLayoutUseCase;

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
      child: EditorPage(
        projectFuture: getIt<GetProjectUseCase>()(projectId),
        imageUrlResolver: imageUrlResolverFor(getIt<AppConfig>()),
        contentId: id,
        getEditorLayoutUseCase: getIt<GetEditorLayoutUseCase>(),
        saveEditorLayoutUseCase: getIt<SaveEditorLayoutUseCase>(),
      ),
    );
  }

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  // `late final` com fallback: só cria (e só possui) um controller próprio
  // quando a página não recebeu um pelo construtor (D19) — o mesmo padrão
  // de opcionalidade do `contentId`, para que `editor_perf_test.dart` e
  // `canvas_panel_golden_test.dart` continuem montando `EditorPage` sem DI.
  late final EditorLayoutController _layoutController =
      widget.layoutController ??
      EditorLayoutController(
        getLayoutUseCase: widget.getEditorLayoutUseCase,
        saveLayoutUseCase: widget.saveEditorLayoutUseCase,
      );

  bool get _ownsLayoutController => widget.layoutController == null;

  @override
  void dispose() {
    if (_ownsLayoutController) _layoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorViewportGate(
      contentId: widget.contentId,
      child: BlocBuilder<EditorCubit, EditorState>(
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType,
        builder: (context, state) => switch (state) {
          EditorLoading() => _editorBootScaffold,
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
          // D13: só monta o workspace depois que a largura restaurada já
          // chegou reclampada — sem isto, o `ResizableSplitView` nasceria
          // com o padrão e nunca reagiria a um boot que termina depois do
          // primeiro frame.
          EditorReady() => FutureBuilder<void>(
            future: _layoutController.ready,
            builder: (context, snapshot) =>
                snapshot.connectionState == ConnectionState.done
                ? EditorWorkspace(
                    projectFuture: widget.projectFuture,
                    imageUrlResolver: widget.imageUrlResolver,
                    layoutController: _layoutController,
                  )
                : _editorBootScaffold,
          ),
        },
      ),
    );
  }
}

String _messageFor(Failure failure) => switch (failure) {
  NetworkFailure() => 'Sem conexão com o servidor. Tente de novo.',
  NotFoundFailure() => 'Conteúdo não encontrado.',
  ConflictFailure(message: final m) => m,
  ValidationFailure(message: final m) => 'Spec inválido: $m',
  UnexpectedFailure() => 'Algo deu errado ao abrir o editor.',
};
