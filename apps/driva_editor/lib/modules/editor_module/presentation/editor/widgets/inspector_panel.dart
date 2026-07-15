import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/editor_colors.dart';
import 'inspector/inspector.dart';
import 'prop_field_editor.dart';

class InspectorPanel extends StatelessWidget {
  const InspectorPanel({
    super.key,
    required this.node,
    required this.isContent,
    required this.contentName,
    required this.contentSlug,
    required this.onUpdateProps,
    required this.onRemove,
  });

  final SduiNode? node;
  final bool isContent;
  final String contentName;
  final String contentSlug;
  final void Function(String nodeId, Map<String, dynamic> patch) onUpdateProps;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final node = this.node;
    final colors = Theme.of(context).extension<EditorColors>()!;

    if (node == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectorHeader(
            title: 'Conteúdo',
            subtitle: '$contentName · slug $contentSlug',
            iconType: null,
            onRemove: null,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Text(
                  'Conteúdo vazio. Adicione um widget para começar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.inkMuted,
                    fontSize: AppTypography.base,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final descriptor = descriptorFor(node.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorHeader(
          title: isContent ? 'Conteúdo' : (descriptor?.label ?? node.type),
          subtitle: isContent
              ? '$contentName · slug $contentSlug'
              : 'id ${node.id}',
          iconType: isContent ? null : node.type,
          onRemove: isContent ? null : () => onRemove(node.id),
        ),
        Expanded(
          child: descriptor == null || descriptor.fields.isEmpty
              ? Center(
                  child: Text(
                    'Sem propriedades editáveis.',
                    style: TextStyle(
                      color: colors.inkMuted,
                      fontSize: AppTypography.base,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                  children: [
                    for (final group in _groupsInOrder(descriptor)) ...[
                      GroupHeader(label: group),
                      for (final field in descriptor.fields.where(
                        (f) => f.group == group,
                      ))
                        PropFieldEditor(
                          // Sem key por nó, o campo mantém o texto do nó anterior.
                          key: ValueKey('${node.id}_${field.key}'),
                          field: field,
                          value: node.properties[field.key],
                          onChanged: (value) =>
                              onUpdateProps(node.id, {field.key: value}),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  List<String> _groupsInOrder(WidgetDescriptor descriptor) {
    final groups = <String>[];
    for (final field in descriptor.fields) {
      if (!groups.contains(field.group)) groups.add(field.group);
    }
    return groups;
  }
}
