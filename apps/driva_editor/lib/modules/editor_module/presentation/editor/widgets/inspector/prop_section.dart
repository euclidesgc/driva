import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/prop_section_header.dart';
import 'package:flutter/material.dart';

/// Expansão é estado efêmero e local: mora aqui, não no cubit, para o painel
/// inteiro não reconstruir a cada abre-e-fecha.
class PropSection extends StatefulWidget {
  const PropSection({
    required this.label,
    required this.summary,
    required this.children,
    this.initiallyExpanded = true,
    this.onExpandedChanged,
    super.key,
  });

  final String label;
  final String summary;
  final List<Widget> children;
  final bool initiallyExpanded;

  /// Chamado a cada abre-e-fecha, para quem quiser persistir o estado
  /// (F6) — este widget continua sem saber onde/se isso é lembrado.
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<PropSection> createState() => _PropSectionState();
}

class _PropSectionState extends State<PropSection> {
  late bool _isExpanded = widget.initiallyExpanded;

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    widget.onExpandedChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: colors.border),
        PropSectionHeader(
          label: widget.label,
          summary: widget.summary,
          isExpanded: _isExpanded,
          onToggle: _toggle,
        ),
        if (_isExpanded) ...widget.children,
      ],
    );
  }
}
