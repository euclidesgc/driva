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
    required this.onRemove,
    required this.onWrap,
    this.collapsedSections,
    this.compareSection,
    super.key,
  });

  final SduiNode? node;
  final bool isRoot;
  final Map<String, dynamic> safeArea;
  final String contentName;
  final String contentSlug;
  final void Function(String nodeId, Map<String, dynamic> patch) onUpdateProps;
  final ValueChanged<Map<String, dynamic>> onUpdateSafeAreaProps;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onWrap;

  /// O que difere da versão comparada, desenhado abaixo do cabeçalho quando o
  /// modo de comparação está ativo. Chega pronto de fora porque o dado de
  /// comparação não passa pelo `InspectorVm` — ver `InspectorCompareSection`.
  final Widget? compareSection;

  /// Repassado a `InspectorPropList` — ver o doc lá para a decisão (Q2/P3).
  final ValueNotifier<Set<String>>? collapsedSections;

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
              collapsedSections: collapsedSections,
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
          title: descriptor?.label ?? node.type,
          subtitle: 'id ${node.id}',
          iconType: node.type,
          onRemove: () => onRemove(node.id),
          removeLabel: isRoot ? clearContentLabel : removeNodeLabel,
          onWrap: onWrap,
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
                  nodeId: node.id,
                  properties: node.properties,
                  descriptor: descriptor,
                  onUpdateProps: (patch) => onUpdateProps(node.id, patch),
                  collapsedSections: collapsedSections,
                ),
        ),
      ],
    );
  }
}
