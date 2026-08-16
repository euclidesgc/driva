import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_intents.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditorShortcuts extends StatelessWidget {
  const EditorShortcuts({required this.child, super.key});

  final Widget child;

  /// Este `Shortcuts` fica **abaixo** do `DefaultTextEditingShortcuts` do
  /// `WidgetsApp`, então ele vence a disputa mesmo com o cursor num campo do
  /// Inspector: sem a guarda, `Delete` apagaria o nó selecionado em vez do
  /// caractere. Salvar e desfazer ficam de fora de propósito — são globais.
  bool get _isEditingText {
    final focused = FocusManager.instance.primaryFocus?.context;
    return focused?.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    // D7: alcança o `EditorLayoutController` pelo soquete, não por um sexto
    // parâmetro de construtor a partir de `EditorWorkspace` (`VR-16-02`).
    final layoutController = EditorLayoutScope.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: layoutController.isFullscreen,
      builder: (context, isFullscreen, staticChild) => Shortcuts(
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              const SaveIntent(),
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
              const UndoIntent(),
          const SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: true,
            shift: true,
          ): const RedoIntent(),
          const SingleActivator(LogicalKeyboardKey.keyY, control: true):
              const RedoIntent(),
          const SingleActivator(LogicalKeyboardKey.keyD, control: true):
              const DuplicateIntent(),
          const SingleActivator(LogicalKeyboardKey.keyC, control: true):
              const CopyNodeIntent(),
          const SingleActivator(LogicalKeyboardKey.keyV, control: true):
              const PasteNodeIntent(),
          const SingleActivator(LogicalKeyboardKey.keyG, control: true):
              const WrapIntent(),
          const SingleActivator(LogicalKeyboardKey.delete):
              const DeleteIntent(),
          // F7/D16: `Esc` só sai do fullscreen enquanto ele está ativo;
          // fora dele, a tecla continua exclusiva de ClearSelectionIntent.
          const SingleActivator(LogicalKeyboardKey.escape): isFullscreen
              ? const ExitFullscreenIntent()
              : const ClearSelectionIntent(),
        },
        child: Actions(
          actions: {
            SaveIntent: CallbackAction<SaveIntent>(
              onInvoke: (_) => cubit.save(),
            ),
            UndoIntent: CallbackAction<UndoIntent>(
              onInvoke: (_) => cubit.undo(),
            ),
            RedoIntent: CallbackAction<RedoIntent>(
              onInvoke: (_) => cubit.redo(),
            ),
            DeleteIntent: CallbackAction<DeleteIntent>(
              onInvoke: (_) => _isEditingText ? null : cubit.removeSelected(),
            ),
            DuplicateIntent: CallbackAction<DuplicateIntent>(
              onInvoke: (_) =>
                  _isEditingText ? null : cubit.duplicateSelected(),
            ),
            CopyNodeIntent: CallbackAction<CopyNodeIntent>(
              onInvoke: (_) => _isEditingText ? null : cubit.copySelected(),
            ),
            PasteNodeIntent: CallbackAction<PasteNodeIntent>(
              onInvoke: (_) => _isEditingText ? null : cubit.paste(),
            ),
            WrapIntent: CallbackAction<WrapIntent>(
              onInvoke: (_) =>
                  _isEditingText ? null : cubit.wrapSelected('column'),
            ),
            ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
              onInvoke: (_) => _isEditingText ? null : cubit.selectNode(null),
            ),
            ExitFullscreenIntent: CallbackAction<ExitFullscreenIntent>(
              onInvoke: (_) => layoutController.exitFullscreen(),
            ),
          },
          child: Focus(autofocus: true, child: staticChild!),
        ),
      ),
      child: child,
    );
  }
}
