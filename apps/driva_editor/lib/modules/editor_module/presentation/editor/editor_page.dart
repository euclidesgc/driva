import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../core/error/error.dart';
import '../../../../core/theme/editor_colors.dart';
import '../../../../core/theme/widgets/resizable_split_view.dart';
import '../../../../injection.dart';
import '../../../projects_module/projects_module.dart';
import '../../domain/use_cases/use_cases.dart';
import 'cubit/editor_cubit.dart';
import 'device_preset.dart';
import 'widgets/canvas_panel.dart';
import 'widgets/editor_top_bar.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/json_preview_panel.dart';
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
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_messageFor(s.failure)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.goNamed(ProjectsRoutes.projectsName),
                  child: const Text('Voltar para os projetos'),
                ),
              ],
            ),
          ),
        ),
        EditorReady() => const _EditorWorkspace(),
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

/// Casca do editor pronto. Construída UMA vez (a `buildWhen` acima só troca no
/// tipo do estado); os painéis internos assinam suas fatias via [BlocSelector].
class _EditorWorkspace extends StatelessWidget {
  const _EditorWorkspace();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    final colors = Theme.of(context).extension<EditorColors>()!;

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
            appBar: const EditorTopBar(),
            body: ResizableSplitView(
              left: const _LeftPanel(),
              center: const _CenterArea(),
              right: ColoredBox(
                color: colors.panel,
                child: const _InspectorArea(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Painel esquerdo: paleta (sem dependência de estado → construída uma vez) e
/// árvore (rebuilda só quando a ESTRUTURA ou a seleção mudam, não a cada tecla).
class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    final colors = Theme.of(context).extension<EditorColors>()!;
    return ColoredBox(
      color: colors.panel,
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
                  const WidgetPalettePanel(),
                  BlocSelector<EditorCubit, EditorState, String>(
                    // Assinatura de estrutura + seleção: props não a alteram,
                    // então editar uma propriedade NÃO reconstrói a árvore.
                    selector: (state) {
                      if (state is! EditorReady) return '';
                      final root = state.document.root;
                      final structure = root == null ? '' : _structureKey(root);
                      return '$structure#${state.selectedNodeId ?? ''}';
                    },
                    builder: (context, _) {
                      final state = cubit.state;
                      if (state is! EditorReady) {
                        return const SizedBox.shrink();
                      }
                      return WidgetTreePanel(
                        root: state.document.root,
                        selectedNodeId: state.selectedNodeId,
                        onSelect: cubit.selectNode,
                        onRemove: cubit.removeNode,
                        onAddInto: (type, parentId, index) => cubit.addNode(
                          type,
                          parentId: parentId,
                          index: index,
                        ),
                        onMoveInto: cubit.moveNode,
                      );
                    },
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

/// Área central com abas ao estilo VS Code: alterna entre o **Mock** (canvas)
/// e o **JSON** do spec ao vivo. Só a casca (a `TabBar`) vive aqui; cada aba
/// assina sua própria fatia do cubit, então trocar de aba não reconstrói a
/// outra desnecessariamente.
class _CenterArea extends StatelessWidget {
  const _CenterArea();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.panel,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  height: 40,
                  child: _CenterTabLabel(icon: Icons.smartphone, label: 'Mock'),
                ),
                Tab(
                  height: 40,
                  child: _CenterTabLabel(
                    icon: Icons.data_object,
                    label: 'JSON',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ColoredBox(color: colors.canvasBackdrop, child: _CanvasArea()),
                const JsonPreviewPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterTabLabel extends StatelessWidget {
  const _CenterTabLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
    );
  }
}

/// Canvas central: reage só a `device`/`zoom` (o preview do documento é
/// assinado e throttled dentro do próprio [CanvasPanel]).
class _CanvasArea extends StatelessWidget {
  const _CanvasArea();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    return BlocSelector<
      EditorCubit,
      EditorState,
      ({DevicePreset device, double zoom})
    >(
      selector: (state) => state is EditorReady
          ? (device: state.device, zoom: state.zoom)
          : (device: DevicePreset.smartphone, zoom: 0.9),
      builder: (context, vm) => CanvasPanel(
        device: vm.device,
        zoom: vm.zoom,
        onSelect: cubit.selectNode,
        onChangeDevice: cubit.changeDevice,
        onChangeZoom: cubit.changeZoom,
        onAddToRoot: (type) {
          final state = cubit.state;
          if (state is! EditorReady) return;
          final root = state.document.root;
          // Conteúdo vazio: o nó vira a raiz (parentId null resolve isso).
          cubit.addNode(type, parentId: root?.id);
        },
      ),
    );
  }
}

/// Inspector: rebuilda só quando a seleção muda ou o nó inspecionado muda de
/// props (editar OUTRO nó não o reconstrói).
class _InspectorArea extends StatelessWidget {
  const _InspectorArea();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    return BlocSelector<EditorCubit, EditorState, _InspectorVm?>(
      selector: (state) {
        if (state is! EditorReady) return null;
        final root = state.document.root;
        final node = state.selectedNode ?? root;
        // Selecionar a raiz a trata como um nó normal (com label + remover);
        // "Conteúdo" é só a visão padrão quando nada está selecionado.
        final isContent = state.selectedNode == null;
        return _InspectorVm(
          node: node,
          isContent: isContent,
          contentName: state.document.name,
          contentSlug: state.document.slug,
        );
      },
      builder: (context, vm) => vm == null
          ? const SizedBox.shrink()
          : InspectorPanel(
              node: vm.node,
              isContent: vm.isContent,
              contentName: vm.contentName,
              contentSlug: vm.contentSlug,
              onUpdateProps: cubit.updateProps,
              onRemove: cubit.removeNode,
            ),
    );
  }
}

class _InspectorVm {
  const _InspectorVm({
    required this.node,
    required this.isContent,
    required this.contentName,
    required this.contentSlug,
  });

  final SduiNode? node;
  final bool isContent;
  final String contentName;
  final String contentSlug;

  @override
  bool operator ==(Object other) =>
      other is _InspectorVm &&
      other.node == node &&
      other.isContent == isContent &&
      other.contentName == contentName &&
      other.contentSlug == contentSlug;

  @override
  int get hashCode => Object.hash(node, isContent, contentName, contentSlug);
}

/// Chave leve da estrutura da árvore (id + tipo + nº de filhos, recursivo).
/// Muda em inserção/remoção/movimento; NÃO muda ao editar props.
String _structureKey(SduiNode node) {
  final buffer = StringBuffer('${node.id}:${node.type}(');
  for (final child in node.children) {
    buffer.write(_structureKey(child));
    buffer.write(',');
  }
  buffer.write(')');
  return buffer.toString();
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
