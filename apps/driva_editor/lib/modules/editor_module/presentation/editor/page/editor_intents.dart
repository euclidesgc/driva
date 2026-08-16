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

/// `Esc` (F7/D16) — só ocupa a tecla enquanto o modo tela cheia está ativo;
/// fora dele, `Esc` continua livre para [ClearSelectionIntent]. Secundário
/// ao botão da `CanvasToolbar`: pendente de verificação ao vivo no Chrome
/// (aceite 35), a mesma lição do `Ctrl+Shift+W` acima.
class ExitFullscreenIntent extends Intent {
  const ExitFullscreenIntent();
}
