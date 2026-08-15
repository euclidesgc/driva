import 'package:flutter/widgets.dart';

class SaveIntent extends Intent {
  const SaveIntent();
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

class DuplicateIntent extends Intent {
  const DuplicateIntent();
}

class CopyNodeIntent extends Intent {
  const CopyNodeIntent();
}

class PasteNodeIntent extends Intent {
  const PasteNodeIntent();
}

/// `Ctrl+G` (D8, item 38) — convenção de "group" em Figma/FlutterFlow.
/// `Ctrl+Shift+W` foi cogitado e descartado: o Chrome consome a tecla antes
/// do app em Flutter Web.
class WrapIntent extends Intent {
  const WrapIntent();
}
