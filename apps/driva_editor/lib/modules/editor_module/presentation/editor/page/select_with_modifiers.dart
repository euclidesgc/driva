import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:flutter/services.dart';

/// Ponto único que lê os modificadores do teclado para a seleção: Shift,
/// Ctrl ou Cmd + clique soma/remove o nó da multi-seleção; clique simples (ou
/// `null`, limpar) volta à seleção única. Árvore e canvas usam o mesmo.
void selectWithModifiers(EditorCubit cubit, String? id) {
  final keyboard = HardwareKeyboard.instance;
  final additive =
      keyboard.isShiftPressed ||
      keyboard.isControlPressed ||
      keyboard.isMetaPressed;
  if (id != null && additive) {
    cubit.toggleNodeSelection(id);
  } else {
    cubit.selectNode(id);
  }
}
