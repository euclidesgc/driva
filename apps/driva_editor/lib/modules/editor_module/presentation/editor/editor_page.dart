import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets/resizable_split_view.dart';
import '../../../../injection.dart';
import '../../domain/use_cases/use_cases.dart';
import 'cubit/editor_cubit.dart';
import 'widgets/canvas_panel.dart';
import 'widgets/editor_top_bar.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/widget_palette_panel.dart';
import 'widgets/widget_tree_panel.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    final id = state.pathParameters['id'];
    // Deep link malformado não é crash, é tela tratada.
    if (id == null || id.trim().isEmpty) return const _InvalidContentScreen();

    return BlocProvider(
      create: (_) => EditorCubit(
        loadContentUseCase: getIt<LoadContentUseCase>(),
        saveDraftUseCase: getIt<SaveDraftUseCase>(),
      )..loadContent(id),
      child: const EditorPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorCubit, EditorState>(
      builder: (context, state) {
        return switch (state) {
          EditorLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          final EditorLoadFailure s => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_messageFor(s.failure)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.goNamed('contents'),
                    child: const Text('Voltar para os conteúdos'),
                  ),
                ],
              ),
            ),
          ),
          final EditorReady s => _EditorWorkspace(state: s),
        };
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

class _EditorWorkspace extends StatelessWidget {
  const _EditorWorkspace({required this.state});

  final EditorReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();

    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const _SaveIntent(),
        const SingleActivator(LogicalKeyboardKey.delete): const _DeleteIntent(),
      },
      child: Actions(
        actions: {
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) => cubit.save(),
          ),
          _DeleteIntent: CallbackAction<_DeleteIntent>(
            onInvoke: (_) => cubit.removeSelected(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: EditorTopBar(state: state, onSave: cubit.save),
            body: ResizableSplitView(
              left: _LeftPanel(state: state),
              center: ColoredBox(
                color: AppTheme.canvas,
                child: CanvasPanel(
                  state: state,
                  onSelect: cubit.selectNode,
                  onChangeDevice: cubit.changeDevice,
                  onChangeZoom: cubit.changeZoom,
                  onAddToRoot: (type) =>
                      cubit.addNode(type, parentId: state.document.root.id),
                ),
              ),
              right: ColoredBox(
                color: AppTheme.surface,
                child: InspectorPanel(
                  state: state,
                  onUpdateProps: cubit.updateProps,
                  onRemove: cubit.removeNode,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({required this.state});

  final EditorReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    return ColoredBox(
      color: AppTheme.surface,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Widgets', height: 40),
                Tab(text: 'Árvore', height: 40),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  WidgetPalettePanel(onAdd: cubit.addNode),
                  WidgetTreePanel(
                    root: state.document.root,
                    selectedNodeId: state.selectedNodeId,
                    onSelect: cubit.selectNode,
                    onRemove: cubit.removeNode,
                    onAddInto: (type, parentId, index) =>
                        cubit.addNode(type, parentId: parentId, index: index),
                    onMoveInto: cubit.moveNode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _DeleteIntent extends Intent {
  const _DeleteIntent();
}

/// id malformado na URL: fallback tratado, nunca crash.
class _InvalidContentScreen extends StatelessWidget {
  const _InvalidContentScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('Conteúdo inválido.')),
    );
  }
}
