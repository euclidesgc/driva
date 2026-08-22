import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_compare_side.dart';
import 'package:flutter/material.dart';

/// Alternador entre os dois mocks quando a janela não comporta os dois lado
/// a lado. Segmented, não abas: os dois lados são simultâneos por natureza e
/// o controle precisa deixar claro qual está oculto, não sugerir navegação.
class CanvasCompareSideToggle extends StatelessWidget {
  const CanvasCompareSideToggle({
    required this.side,
    required this.candidateLabel,
    required this.onChanged,
    super.key,
  });

  final CanvasCompareSide side;

  /// Título curto da candidata ("Versão N" ou nota-ou-"Ponto salvo") —
  /// `historyEntryTitle`.
  final String candidateLabel;
  final ValueChanged<CanvasCompareSide> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CanvasCompareSide>(
      showSelectedIcon: false,
      segments: [
        const ButtonSegment(
          value: CanvasCompareSide.draft,
          icon: Icon(Icons.edit_outlined),
          label: Text('Rascunho'),
          tooltip: 'Ver o rascunho que você está editando',
        ),
        ButtonSegment(
          value: CanvasCompareSide.candidate,
          icon: const Icon(Icons.history),
          label: Text(candidateLabel),
          tooltip: 'Ver como estava: $candidateLabel',
        ),
      ],
      selected: {side},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
