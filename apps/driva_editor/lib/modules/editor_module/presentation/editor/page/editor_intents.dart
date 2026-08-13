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
