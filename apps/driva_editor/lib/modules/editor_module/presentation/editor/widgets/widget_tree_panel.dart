import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/widget_tree.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class WidgetTreePanel extends StatelessWidget {
  const WidgetTreePanel({
    required this.root,
    required this.selectedNodeId,
    required this.onSelect,
    required this.onRemove,
    required this.onDropNew,
    required this.onDropMove,
    required this.onDropNewAt,
    required this.onDropMoveAt,
    required this.nodeDiagnostics,
    this.compareDiffs = const {},
    this.compareOnlyInBase = const {},
    this.compareGhostNodes = const [],
    this.pageDiffMarkers = const [],
    this.isReadOnly = false,
    super.key,
  });

  final SduiNode? root;

  /// Agrupado uma vez fora deste widget (`diagnosticsByNode`) — cada linha só
  /// faz uma leitura de mapa, nunca varre `diagnoseTree` de novo.
  final Map<String, List<SpecDiagnostic>> nodeDiagnostics;

  /// Índice do diff da comparação por nó do rascunho — vazio fora do modo.
  final Map<String, NodeDiff> compareDiffs;
  final Set<String> compareOnlyInBase;

  /// Nós que só existem na versão comparada, em ordem de árvore da candidata:
  /// não têm linha no rascunho e entram como linhas-fantasma no fim da lista.
  final List<SduiNode> compareGhostNodes;

  /// `safeArea` e metadados alterados — marcadores da linha fixa da página.
  final List<VersionCompareMarkerKind> pageDiffMarkers;

  /// Rascunho congelado pelo modo de comparação: a árvore vira um mapa de
  /// leitura — selecionar continua, arrastar e excluir saem de cena junto
  /// com as faixas de soltura, que sem arraste nenhum só convidariam para
  /// algo que não acontece.
  final bool isReadOnly;

  /// `null` = a página (área segura) está no Inspector.
  final String? selectedNodeId;
  final ValueChanged<String?> onSelect;
  final ValueChanged<String> onRemove;

  /// Com `targetId` null (conteúdo vazio), o nó vira a raiz.
  final void Function(String type, String? targetId) onDropNew;

  final void Function(String nodeId, String targetId) onDropMove;

  /// Frestas entre linhas: posição exata dentro da lista de filhos do pai.
  final void Function(String type, String parentId, int index) onDropNewAt;

  final void Function(String nodeId, String parentId, int index) onDropMoveAt;

  @override
  Widget build(BuildContext context) {
    final root = this.root;
    final rows = <Widget>[];
    if (root != null) _buildRows(rows, root, root, depth: 0);
    rows.addAll(
      compareGhostNodes.map((node) => CompareGhostTreeRow(node: node)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTreeRow(
          isSelected: selectedNodeId == null,
          onSelect: () => onSelect(null),
          diffMarkerKinds: pageDiffMarkers,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            children: rows,
          ),
        ),
        if (!isReadOnly)
          DropZone(
            label: root == null
                ? 'Solte um widget aqui para começar'
                : 'Soltar aqui adiciona ao fim do conteúdo',
            onAccept: (payload) => switch (payload) {
              PaletteDragPayload(:final type) => onDropNew(type, root?.id),
              NodeDragPayload(:final nodeId) when root != null => onDropMove(
                nodeId,
                root.id,
              ),
              NodeDragPayload() => null,
            },
          ),
      ],
    );
  }

  VersionCompareMarkerKind? _markerKindFor(String nodeId) {
    if (compareOnlyInBase.contains(nodeId)) {
      return VersionCompareMarkerKind.onlyInBase;
    }
    final diff = compareDiffs[nodeId];
    if (diff == null) return null;
    if (diff.typeChanged) return VersionCompareMarkerKind.typeChanged;
    if (diff.propertiesChanged) {
      return VersionCompareMarkerKind.propertiesChanged;
    }
    if (diff.eventsChanged) return VersionCompareMarkerKind.eventsChanged;
    return null;
  }

  void _buildRows(
    List<Widget> rows,
    SduiNode root,
    SduiNode node, {
    required int depth,
  }) {
    rows.add(
      TreeRow(
        node: node,
        depth: depth,
        isRoot: node.id == root.id,
        isSelected: node.id == selectedNodeId,
        diagnostics: nodeDiagnostics[node.id] ?? const [],
        diffMarkerKind: _markerKindFor(node.id),
        onSelect: () => onSelect(node.id),
        onRemove: isReadOnly ? null : () => onRemove(node.id),
        isDraggable: !isReadOnly,
        onAccept: (payload) => switch (payload) {
          PaletteDragPayload(:final type) => onDropNew(type, node.id),
          NodeDragPayload(:final nodeId) => onDropMove(nodeId, node.id),
        },
      ),
    );
    if (node.child != null) {
      _buildRows(rows, root, node.child!, depth: depth + 1);
    }

    final acceptsList =
        (descriptorFor(node.type)?.slot ?? SlotKind.none) == SlotKind.multi;
    for (var index = 0; index <= node.children.length; index++) {
      if (acceptsList && !isReadOnly) {
        rows.add(
          TreeGapDropZone(
            key: ValueKey('gap_${node.id}_$index'),
            depth: depth + 1,
            parentId: node.id,
            index: index,
            onDropNew: onDropNewAt,
            onDropMove: onDropMoveAt,
          ),
        );
      }
      if (index < node.children.length) {
        _buildRows(rows, root, node.children[index], depth: depth + 1);
      }
    }
  }
}
