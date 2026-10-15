import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/inspector.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/remove_node_labels.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Sem nó selecionado, o Inspector edita a **página**: a área segura que
/// embrulha todo conteúdo, chrome fixo que não aparece na paleta nem na árvore.
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({
    required this.node,
    required this.isRoot,
    required this.safeArea,
    required this.contentName,
    required this.contentSlug,
    required this.onUpdateProps,
    required this.onUpdateSafeAreaProps,
    required this.onBindProp,
    required this.onUnbindProp,
    required this.onRemove,
    required this.onWrap,
    this.onRename,
    this.multiNodes = const [],
    this.onUpdatePropsBatch,
    this.collapsedSections,
    this.compareSection,
    this.isReadOnly = false,
    super.key,
  });

  final SduiNode? node;

  /// Dois ou mais nós: o inspector mostra só os campos em comum e aplica a
  /// edição a todos, numa única entrada de histórico.
  final List<SduiNode> multiNodes;
  final void Function(List<String> ids, Map<String, dynamic> patch)?
  onUpdatePropsBatch;
  final bool isRoot;
  final Map<String, dynamic> safeArea;
  final String contentName;
  final String contentSlug;
  final void Function(String nodeId, Map<String, dynamic> patch) onUpdateProps;
  final ValueChanged<Map<String, dynamic>> onUpdateSafeAreaProps;
  final void Function(String nodeId, String key, BoundPropValue binding)
  onBindProp;
  final void Function(String nodeId, String key) onUnbindProp;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onWrap;

  /// Nome de edição do nó; não muda o `id`.
  final void Function(String nodeId, String? name)? onRename;

  /// O que difere da versão comparada, desenhado abaixo do cabeçalho quando o
  /// modo de comparação está ativo. Chega pronto de fora porque o dado de
  /// comparação não passa pelo `InspectorVm` — ver `InspectorCompareSection`.
  final Widget? compareSection;

  /// Repassado a `InspectorPropList` — ver o doc lá para a decisão (Q2/P3).
  final ValueNotifier<Set<String>>? collapsedSections;

  /// Rascunho congelado pelo modo de comparação: some o que edita — excluir,
  /// envolver e os campos —, fica o que informa, inclusive [compareSection],
  /// que é justamente o que se lê durante a comparação.
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final node = this.node;
    final colors = Theme.of(context).extension<EditorColors>()!;

    if (node == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectorHeader(
            title: 'Página',
            subtitle: '$contentName · slug $contentSlug',
            iconType: null,
            onRemove: null,
            onWrap: null,
          ),
          ?compareSection,
          Expanded(
            child: InspectorPropList(
              ownerKey: 'page',
              properties: safeArea,
              descriptor: safeAreaDescriptor,
              onUpdateProps: onUpdateSafeAreaProps,
              // A página (área segura) não tem binding: o inspector dela
              // não oferece o controle de ligação a uma variável aqui.
              onBindProp: (_, _) {},
              onUnbindProp: (_) {},
              collapsedSections: collapsedSections,
              isReadOnly: isReadOnly,
            ),
          ),
        ],
      );
    }

    if (multiNodes.length > 1 && onUpdatePropsBatch != null) {
      return _buildBatch(context, colors);
    }

    final descriptor = descriptorFor(node.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorHeader(
          title: descriptor?.label ?? node.type,
          name: node.name,
          onRename: isReadOnly || onRename == null
              ? null
              : (name) => onRename!(node.id, name),
          subtitle: 'id ${node.id}',
          iconType: node.type,
          onRemove: isReadOnly ? null : () => onRemove(node.id),
          removeLabel: isRoot ? clearContentLabel : removeNodeLabel,
          onWrap: isReadOnly ? null : onWrap,
        ),
        ?compareSection,
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
              : InspectorPropList(
                  ownerKey: node.id,
                  properties: node.properties,
                  descriptor: descriptor,
                  onUpdateProps: (patch) => onUpdateProps(node.id, patch),
                  onBindProp: (key, binding) =>
                      onBindProp(node.id, key, binding),
                  onUnbindProp: (key) => onUnbindProp(node.id, key),
                  collapsedSections: collapsedSections,
                  isReadOnly: isReadOnly,
                ),
        ),
      ],
    );
  }

  // dart format off
  Widget _buildBatch(BuildContext context, EditorColors colors) { // gate1-ok: ramo do build()
  // dart format on
    final fields = commonFields(multiNodes);
    final ids = [for (final n in multiNodes) n.id];
    final first = multiNodes.first;
    final mixed = {
      for (final f in fields)
        if (mixedValue(multiNodes, f.key)) f.key,
    };
    final descriptor = WidgetDescriptor(
      type: 'multi',
      label: '${multiNodes.length} nós selecionados',
      iconName: '',
      category: '',
      slot: SlotKind.none,
      fields: fields,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorHeader(
          title: '${multiNodes.length} nós selecionados',
          subtitle: 'edição em lote',
          iconType: null,
          onRemove: null,
          onWrap: null,
        ),
        Expanded(
          child: fields.isEmpty
              ? Center(
                  child: Text(
                    'Sem campos em comum.',
                    style: TextStyle(
                      color: colors.inkMuted,
                      fontSize: AppTypography.base,
                    ),
                  ),
                )
              : InspectorPropList(
                  ownerKey: 'multi-${ids.join('|')}',
                  properties: {
                    for (final f in fields)
                      if (!mixed.contains(f.key) &&
                          first.properties[f.key] != null)
                        f.key: first.properties[f.key],
                  },
                  descriptor: descriptor,
                  mixedKeys: mixed,
                  onUpdateProps: (patch) => onUpdatePropsBatch!(ids, patch),
                  // Ligação a variável fica fora do lote.
                  onBindProp: (_, _) {},
                  onUnbindProp: (_) {},
                  collapsedSections: collapsedSections,
                  isReadOnly: isReadOnly,
                ),
        ),
      ],
    );
  }
}
