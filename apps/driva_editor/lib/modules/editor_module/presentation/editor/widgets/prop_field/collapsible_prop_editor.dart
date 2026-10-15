import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/prop_group_summary.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_summary_row.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Expansão é estado efêmero e local, como em `PropSection`: não vai para o
/// cubit nem para o spec.
class CollapsiblePropEditor extends StatefulWidget {
  const CollapsiblePropEditor({
    required this.field,
    required this.value,
    required this.child,
    this.initiallyExpanded = false,
    super.key,
  });

  final PropField field;
  final Object? value;

  final Widget child;
  final bool initiallyExpanded;

  @override
  State<CollapsiblePropEditor> createState() => _CollapsiblePropEditorState();
}

class _CollapsiblePropEditorState extends State<CollapsiblePropEditor> {
  late bool _isExpanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PropSummaryRow(
          label: widget.field.label,
          summary: PropGroupSummary.describe(widget.field, widget.value),
          isExpanded: _isExpanded,
          onToggle: _toggle,
        ),
        if (_isExpanded) widget.child,
      ],
    );
  }
}
