import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../core/theme/app_theme.dart';
import '../cubit/editor_cubit.dart';
import 'palette_icons.dart';
import 'prop_field_editor.dart';

/// Inspector: o formulário do nó selecionado, 100% derivado do catálogo
/// (WidgetDescriptor/PropField). Sem seleção, mostra as propriedades do
/// conteúdo (o root column).
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({
    super.key,
    required this.state,
    required this.onUpdateProps,
    required this.onRemove,
  });

  final EditorReady state;
  final void Function(String nodeId, Map<String, dynamic> patch) onUpdateProps;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedNode;
    final node = selected ?? state.document.root;
    final descriptor = descriptorFor(node.type);
    final isContent = selected == null || node.id == state.document.root.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InspectorHeader(
          title: isContent ? 'Conteúdo' : (descriptor?.label ?? node.type),
          subtitle: isContent
              ? '${state.document.name} · slug ${state.document.slug}'
              : 'id ${node.id}',
          iconType: isContent ? null : node.type,
          onRemove: isContent ? null : () => onRemove(node.id),
        ),
        Expanded(
          child: descriptor == null || descriptor.fields.isEmpty
              ? const Center(
                  child: Text(
                    'Sem propriedades editáveis.',
                    style: TextStyle(color: AppTheme.inkMuted, fontSize: 13),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final group in _groupsInOrder(descriptor)) ...[
                      _GroupHeader(label: group),
                      for (final field in descriptor.fields.where(
                        (f) => f.group == group,
                      ))
                        PropFieldEditor(
                          // Key por nó+campo: troca o form quando a seleção muda.
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

  /// Grupos na ordem de primeira aparição (padrão do Inspector).
  List<String> _groupsInOrder(WidgetDescriptor descriptor) {
    final groups = <String>[];
    for (final field in descriptor.fields) {
      if (!groups.contains(field.group)) groups.add(field.group);
    }
    return groups;
  }
}

class _InspectorHeader extends StatelessWidget {
  const _InspectorHeader({
    required this.title,
    required this.subtitle,
    required this.iconType,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final String? iconType;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Icon(
            iconType == null ? Icons.web_asset : paletteIconFor(iconType!),
            size: 18,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.inkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remover bloco (Delete)',
              iconSize: 18,
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 2),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          color: AppTheme.inkMuted,
        ),
      ),
    );
  }
}
