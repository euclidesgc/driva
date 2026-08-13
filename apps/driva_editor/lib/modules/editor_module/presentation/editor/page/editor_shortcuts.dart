import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_intents.dart';
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
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyS, control: true): SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoIntent(),
        SingleActivator(LogicalKeyboardKey.delete): DeleteIntent(),
        SingleActivator(LogicalKeyboardKey.escape): ClearSelectionIntent(),
      },
      child: Actions(
        actions: {
          SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) => cubit.save()),
          UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => cubit.undo()),
          RedoIntent: CallbackAction<RedoIntent>(onInvoke: (_) => cubit.redo()),
          DeleteIntent: CallbackAction<DeleteIntent>(
            onInvoke: (_) => _isEditingText ? null : cubit.removeSelected(),
          ),
          ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
            onInvoke: (_) => _isEditingText ? null : cubit.selectNode(null),
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
