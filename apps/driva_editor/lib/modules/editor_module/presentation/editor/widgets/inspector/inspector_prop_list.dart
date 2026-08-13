import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/widgets/input/search_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/prop_group_summary.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/prop_section.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// A busca é estado local: filtrar não pode reconstruir o cabeçalho do
/// Inspector nem o canvas.
class InspectorPropList extends StatefulWidget {
  const InspectorPropList({
    required this.node,
    required this.descriptor,
    required this.onUpdateProps,
    super.key,
  });

  final SduiNode node;
  final WidgetDescriptor descriptor;
  final void Function(String nodeId, Map<String, dynamic> patch) onUpdateProps;

  @override
  State<InspectorPropList> createState() => _InspectorPropListState();
}

class _InspectorPropListState extends State<InspectorPropList> {
  String _query = '';

  List<String> get _groupsInOrder {
    final groups = <String>[];
    for (final field in widget.descriptor.fields) {
      if (!groups.contains(field.group)) groups.add(field.group);
    }
    return groups;
  }

  List<PropField> _fieldsOf(String group) => [
    for (final field in widget.descriptor.fields)
      if (field.group == group && _matches(field)) field,
  ];

  bool _matches(PropField field) =>
      _query.isEmpty ||
      field.label.toLowerCase().contains(_query) ||
      field.key.toLowerCase().contains(_query);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final groups = [
      for (final group in _groupsInOrder)
        if (_fieldsOf(group).isNotEmpty) group,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s12,
            AppSpacing.s8,
            AppSpacing.s12,
            AppSpacing.s8,
          ),
          child: SearchField(
            hintText: 'Buscar propriedade…',
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma propriedade encontrada.',
                    style: TextStyle(
                      color: colors.inkMuted,
                      fontSize: AppTypography.base,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                  children: [
                    for (final group in groups)
                      PropSection(
                        // Sem key por grupo, fechar uma seção "moveria" o
                        // estado para a seção que assumir o índice ao filtrar.
                        key: ValueKey('${widget.descriptor.type}_$group'),
                        label: group,
                        summary: PropGroupSummary.of(
                          _fieldsOf(group),
                          widget.node.properties,
                        ),
                        children: [
                          for (final field in _fieldsOf(group))
                            PropFieldEditor(
                              key: ValueKey(
                                '${widget.node.id}_${field.key}',
                              ),
                              field: field,
                              value: widget.node.properties[field.key],
                              onChanged: (value) => widget.onUpdateProps(
                                widget.node.id,
                                {field.key: value},
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
