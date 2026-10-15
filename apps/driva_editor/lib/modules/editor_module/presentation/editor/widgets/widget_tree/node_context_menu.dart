import 'dart:async';

import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/wrapper_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_core/sdui_core.dart';

enum _NodeAction {
  cut,
  copy,
  paste,
  undo,
  redo,
  delete,
  duplicate,
  wrap,
  replace,
  unwrap,
  copyStyle,
  pasteStyle,
}

Future<void> showWrapperPicker(BuildContext context) async {
  final cubit = context.read<EditorCubit>();
  final type = await showDialog<String>(
    context: context,
    builder: (_) => WrapperPickerDialog(
      title: 'Envolver em…',
      types: WrapperPickerDialog.wrapperTypes,
      confirmLabel: 'Envolver',
    ),
  );
  if (type != null) cubit.wrapSelected(type);
}

Future<void> _showReplacePicker(BuildContext context) async {
  final cubit = context.read<EditorCubit>();
  final type = await showDialog<String>(
    context: context,
    builder: (_) => WrapperPickerDialog(
      title: 'Substituir por…',
      types: WrapperPickerDialog.allTypes,
      confirmLabel: 'Substituir',
    ),
  );
  if (type != null) cubit.replaceSelected(type);
}

/// O canvas não oferece "Excluir" ([allowDelete] falso): excluir por lá segue
/// bloqueado de propósito; a árvore é o lugar do gesto destrutivo.
Future<void> showNodeContextMenu(
  BuildContext context, {
  required Offset position,
  required String nodeId,
  bool allowDelete = true,
}) async {
  final cubit = context.read<EditorCubit>();
  final state = cubit.state;
  if (state is! EditorReady) return;
  cubit.selectNode(nodeId);

  final root = state.document.root;
  final isRoot = root?.id == nodeId;
  final isFrozen = state.isReadOnly;
  const frozenReason = 'Rascunho congelado.';
  final unwrapReason = root == null || unwrapNode(root, nodeId) == null
      ? 'Só vale para um widget com filhos dentro de outro.'
      : null;

  PopupMenuEntry<_NodeAction> item(
    _NodeAction action,
    String label, {
    String? shortcut,
    String? disabledReason,
  }) {
    final reason = isFrozen ? frozenReason : disabledReason;
    final row = Row(
      children: [
        Expanded(child: Text(label)),
        if (shortcut != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s16),
            child: Text(shortcut, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
    return PopupMenuItem<_NodeAction>(
      value: action,
      enabled: reason == null,
      child: reason == null ? row : Tooltip(message: reason, child: row),
    );
  }

  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final selected = await showMenu<_NodeAction>(
    context: context,
    position: RelativeRect.fromRect(
      position & Size.zero,
      Offset.zero & overlay.size,
    ),
    items: [
      item(_NodeAction.cut, 'Recortar', shortcut: 'Ctrl+X'),
      item(_NodeAction.copy, 'Copiar', shortcut: 'Ctrl+C'),
      item(_NodeAction.paste, 'Colar', shortcut: 'Ctrl+V'),
      item(
        _NodeAction.undo,
        'Desfazer',
        shortcut: 'Ctrl+Z',
        disabledReason: state.canUndo ? null : 'Nada para desfazer.',
      ),
      item(
        _NodeAction.redo,
        'Refazer',
        shortcut: 'Ctrl+Y',
        disabledReason: state.canRedo ? null : 'Nada para refazer.',
      ),
      if (allowDelete) item(_NodeAction.delete, 'Excluir', shortcut: 'Delete'),
      const PopupMenuDivider(),
      item(
        _NodeAction.duplicate,
        'Duplicar',
        shortcut: 'Ctrl+D',
        disabledReason: isRoot ? 'A raiz não tem irmãos.' : null,
      ),
      item(_NodeAction.wrap, 'Envolver…', shortcut: 'Ctrl+B'),
      item(_NodeAction.replace, 'Substituir…'),
      item(_NodeAction.unwrap, 'Remover widget', disabledReason: unwrapReason),
      const PopupMenuDivider(),
      item(_NodeAction.copyStyle, 'Copiar estilo', shortcut: 'Ctrl+Shift+C'),
      item(_NodeAction.pasteStyle, 'Colar estilo'),
    ],
  );
  if (selected == null || !context.mounted) return;

  switch (selected) {
    case _NodeAction.cut:
      cubit
        ..copySelected()
        ..removeSelected();
    case _NodeAction.copy:
      cubit.copySelected();
    case _NodeAction.paste:
      cubit.paste();
    case _NodeAction.undo:
      cubit.undo();
    case _NodeAction.redo:
      cubit.redo();
    case _NodeAction.delete:
      cubit.removeSelected();
    case _NodeAction.duplicate:
      cubit.duplicateSelected();
    case _NodeAction.wrap:
      unawaited(showWrapperPicker(context));
    case _NodeAction.replace:
      unawaited(_showReplacePicker(context));
    case _NodeAction.unwrap:
      cubit.unwrapSelected();
    case _NodeAction.copyStyle:
      cubit.copyStyleSelected();
    case _NodeAction.pasteStyle:
      cubit.pasteStyleSelected();
  }
}
