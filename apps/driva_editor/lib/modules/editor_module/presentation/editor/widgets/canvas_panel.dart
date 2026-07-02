import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

import '../../../../../core/theme/app_theme.dart';
import '../cubit/editor_cubit.dart';
import '../device_preset.dart';
import 'drag_payload.dart';

/// Canvas central: toolbar (dispositivo + zoom) e a moldura de celular
/// renderizando o documento com o renderer REAL (`SduiView`) — preview fiel
/// por construção. O `nodeWrapper` injeta seleção por clique e contorno.
class CanvasPanel extends StatelessWidget {
  const CanvasPanel({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onChangeDevice,
    required this.onChangeZoom,
    required this.onAddToRoot,
  });

  final EditorReady state;
  final ValueChanged<String?> onSelect;
  final ValueChanged<DevicePreset> onChangeDevice;
  final ValueChanged<double> onChangeZoom;
  final ValueChanged<String> onAddToRoot;

  @override
  Widget build(BuildContext context) {
    final device = state.device;
    return Column(
      children: [
        _CanvasToolbar(
          state: state,
          onChangeDevice: onChangeDevice,
          onChangeZoom: onChangeZoom,
        ),
        Expanded(
          child: DragTarget<DragPayload>(
            // Soltar no canvas (fora da árvore) = adicionar ao fim da página.
            onAcceptWithDetails: (details) {
              if (details.data case PaletteDragPayload(:final type)) {
                onAddToRoot(type);
              }
            },
            builder: (context, candidates, _) => InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(64),
              minScale: 1,
              maxScale: 1,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Transform.scale(
                  scale: state.zoom,
                  alignment: Alignment.topCenter,
                  child: _DeviceFrame(
                    device: device,
                    highlighted: candidates.isNotEmpty,
                    child: _PreviewSurface(state: state, onSelect: onSelect),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CanvasToolbar extends StatelessWidget {
  const _CanvasToolbar({
    required this.state,
    required this.onChangeDevice,
    required this.onChangeZoom,
  });

  final EditorReady state;
  final ValueChanged<DevicePreset> onChangeDevice;
  final ValueChanged<double> onChangeZoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          SegmentedButton<DevicePreset>(
            segments: [
              for (final preset in DevicePreset.values)
                ButtonSegment(
                  value: preset,
                  tooltip:
                      '${preset.label} (${preset.width.toInt()}×${preset.height.toInt()})',
                  icon: Icon(
                    switch (preset) {
                      DevicePreset.smartphone => Icons.smartphone,
                      DevicePreset.android => Icons.phone_android,
                      DevicePreset.tablet => Icons.tablet_mac,
                    },
                    size: 16,
                  ),
                ),
            ],
            selected: {state.device},
            onSelectionChanged: (selection) =>
                onChangeDevice(selection.single),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const Spacer(),
          Text(
            '${state.device.width.toInt()} × ${state.device.height.toInt()}',
            style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted),
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Diminuir zoom',
            iconSize: 18,
            icon: const Icon(Icons.zoom_out),
            onPressed: () => onChangeZoom(state.zoom - 0.1),
          ),
          Text(
            '${(state.zoom * 100).round()}%',
            style: const TextStyle(fontSize: 12),
          ),
          IconButton(
            tooltip: 'Aumentar zoom',
            iconSize: 18,
            icon: const Icon(Icons.zoom_in),
            onPressed: () => onChangeZoom(state.zoom + 0.1),
          ),
        ],
      ),
    );
  }
}

class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({
    required this.device,
    required this.highlighted,
    required this.child,
  });

  final DevicePreset device;
  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: device.width + 24,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E22),
        borderRadius: BorderRadius.circular(36),
        border: highlighted
            ? Border.all(color: AppTheme.primary, width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: device.width,
          height: device.height,
          child: ColoredBox(color: Colors.white, child: child),
        ),
      ),
    );
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({required this.state, required this.onSelect});

  final EditorReady state;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final document = state.document;
    return GestureDetector(
      // Clique no vazio limpa a seleção (volta às propriedades da página).
      onTap: () => onSelect(null),
      child: document.root.children.isEmpty
          ? const _EmptyPreview()
          : SingleChildScrollView(
              child: SduiView.page(
                document,
                onAction: (action) =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Ação "${action.type}" é executada só no app cliente.',
                    ),
                  ),
                ),
                nodeWrapper: (node, built) => _SelectableNode(
                  node: node,
                  built: built,
                  isSelected: node.id == state.selectedNodeId,
                  onSelect: () => onSelect(node.id),
                ),
              ),
            ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swipe_left_alt_outlined,
                size: 40, color: AppTheme.inkMuted),
            SizedBox(height: 12),
            Text(
              'Página vazia.\nArraste um widget da paleta para começar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contorno + rótulo de seleção sobre o widget renderizado.
///
/// `spacer`/tipos de flex NÃO são envolvidos (precisam ser filhos diretos de
/// Row/Column) — eles se selecionam pela árvore.
class _SelectableNode extends StatelessWidget {
  const _SelectableNode({
    required this.node,
    required this.built,
    required this.isSelected,
    required this.onSelect,
  });

  final SduiNode node;
  final Widget built;
  final bool isSelected;
  final VoidCallback onSelect;

  static const _unwrappable = {'spacer'};

  @override
  Widget build(BuildContext context) {
    if (_unwrappable.contains(node.type)) return built;

    final descriptor = descriptorFor(node.type);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: AppTheme.primary, width: 2)
                  : null,
            ),
            child: built,
          ),
          if (isSelected)
            Positioned(
              top: -18,
              left: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: AppTheme.primary,
                child: Text(
                  descriptor?.label ?? node.type,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
