import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

import '../../../../../core/theme/app_theme.dart';
import '../cubit/editor_cubit.dart';
import '../device_preset.dart';
import 'dashed_border_painter.dart';
import 'drag_payload.dart';

/// Canvas central: toolbar (dispositivo + zoom) e a moldura de celular
/// renderizando o documento com o renderer REAL (`SduiView`) — preview fiel
/// por construção. O `nodeWrapper` injeta seleção por clique e contorno.
///
/// Recebe só `device`/`zoom`; o preview do documento é assinado e **throttled**
/// dentro de [_PreviewSurface], para digitação rápida não re-executar o
/// renderer a cada tecla.
class CanvasPanel extends StatelessWidget {
  const CanvasPanel({
    super.key,
    required this.device,
    required this.zoom,
    required this.onSelect,
    required this.onChangeDevice,
    required this.onChangeZoom,
    required this.onAddToRoot,
  });

  final DevicePreset device;
  final double zoom;
  final ValueChanged<String?> onSelect;
  final ValueChanged<DevicePreset> onChangeDevice;
  final ValueChanged<double> onChangeZoom;
  final ValueChanged<String> onAddToRoot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CanvasToolbar(
          device: device,
          zoom: zoom,
          onChangeDevice: onChangeDevice,
          onChangeZoom: onChangeZoom,
        ),
        Expanded(
          child: DragTarget<DragPayload>(
            // Soltar no canvas (fora da árvore) = adicionar ao fim do conteúdo.
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
                  scale: zoom,
                  alignment: Alignment.topCenter,
                  // Isola a pintura do preview do resto do editor.
                  child: RepaintBoundary(
                    child: _DeviceFrame(
                      device: device,
                      highlighted: candidates.isNotEmpty,
                      child: _PreviewSurface(onSelect: onSelect),
                    ),
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
    required this.device,
    required this.zoom,
    required this.onChangeDevice,
    required this.onChangeZoom,
  });

  final DevicePreset device;
  final double zoom;
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
                  icon: Icon(switch (preset) {
                    DevicePreset.smartphone => Icons.smartphone,
                    DevicePreset.android => Icons.phone_android,
                    DevicePreset.tablet => Icons.tablet_mac,
                  }, size: 16),
                ),
            ],
            selected: {device},
            onSelectionChanged: (selection) => onChangeDevice(selection.single),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          const Spacer(),
          Text(
            '${device.width.toInt()} × ${device.height.toInt()}',
            style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted),
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Diminuir zoom',
            iconSize: 18,
            icon: const Icon(Icons.zoom_out),
            onPressed: () => onChangeZoom(zoom - 0.1),
          ),
          Text(
            '${(zoom * 100).round()}%',
            style: const TextStyle(fontSize: 12),
          ),
          IconButton(
            tooltip: 'Aumentar zoom',
            iconSize: 18,
            icon: const Icon(Icons.zoom_in),
            onPressed: () => onChangeZoom(zoom + 0.1),
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
        boxShadow: [
          const BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
          if (highlighted)
            const BoxShadow(
              color: Color(0x66E8602C),
              blurRadius: 20,
              spreadRadius: 2,
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

/// Superfície do preview. Assina `document`/`selectedNodeId` direto do cubit,
/// mas **throttla** a re-renderização do documento (o custo caro é o renderer
/// real): a digitação rápida é coalescida numa janela curta, com render final
/// garantido. A seleção reflete na hora (o contorno precisa ser imediato).
class _PreviewSurface extends StatefulWidget {
  const _PreviewSurface({required this.onSelect});

  final ValueChanged<String?> onSelect;

  @override
  State<_PreviewSurface> createState() => _PreviewSurfaceState();
}

class _PreviewSurfaceState extends State<_PreviewSurface> {
  static const _throttle = Duration(milliseconds: 120);

  late final EditorCubit _cubit = context.read<EditorCubit>();
  late StreamSubscription<EditorState> _subscription;

  late ContentSpec _rendered;
  String? _selectedNodeId;
  Timer? _cooldown;
  bool _pendingRender = false;

  @override
  void initState() {
    super.initState();
    final state = _cubit.state as EditorReady;
    _rendered = state.document;
    _selectedNodeId = state.selectedNodeId;
    _subscription = _cubit.stream.listen(_onState);
  }

  void _onState(EditorState state) {
    if (state is! EditorReady || !mounted) return;

    if (state.selectedNodeId != _selectedNodeId) {
      setState(() => _selectedNodeId = state.selectedNodeId);
    }

    if (state.document != _rendered) {
      if (_cooldown?.isActive ?? false) {
        _pendingRender = true;
      } else {
        _applyDocument();
      }
    }
  }

  void _applyDocument() {
    final state = _cubit.state;
    if (state is! EditorReady || !mounted) return;
    setState(() => _rendered = state.document);
    _pendingRender = false;
    _cooldown = Timer(_throttle, () {
      if (_pendingRender && mounted) _applyDocument();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _cooldown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = _rendered;
    return GestureDetector(
      // Clique no vazio limpa a seleção (volta às propriedades do conteúdo).
      onTap: () => widget.onSelect(null),
      child: document.root.children.isEmpty
          ? const _EmptyPreview()
          : SingleChildScrollView(
              child: SduiView.content(
                document,
                onAction: (action) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Ação "${action.type}" é executada só no app cliente.',
                    ),
                  ),
                ),
                nodeWrapper: (node, built) => _SelectableNode(
                  node: node,
                  built: built,
                  isSelected: node.id == _selectedNodeId,
                  onSelect: () => widget.onSelect(node.id),
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
            Icon(
              Icons.swipe_left_alt_outlined,
              size: 40,
              color: AppTheme.inkMuted,
            ),
            SizedBox(height: 12),
            Text(
              'Conteúdo vazio.\nArraste um widget da paleta para começar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contorno + rótulo sobre o widget renderizado.
///
/// Seleção = contorno sólido + tag destacada. Fora de seleção, cada nó recebe
/// uma **borda tracejada discreta + tag pequena com o nome**, para o usuário
/// perceber que há um componente ali mesmo quando ele é pequeno ou vazio
/// (feedback ao soltar no mock).
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
  static const _hintColor = Color(0x66A0A4AD);

  @override
  Widget build(BuildContext context) {
    if (_unwrappable.contains(node.type)) return built;

    final descriptor = descriptorFor(node.type);
    final label = descriptor?.label ?? node.type;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: Semantics(
        label: label,
        selected: isSelected,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isSelected)
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
                child: built,
              )
            else
              CustomPaint(
                foregroundPainter: const DashedBorderPainter(color: _hintColor),
                child: built,
              ),
            Positioned(
              top: -18,
              left: 0,
              child: _NodeTag(label: label, isSelected: isSelected),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tag pequena com o nome do componente. Destacada quando selecionado; discreta
/// (só um sinal a mais de "há algo aqui") caso contrário.
class _NodeTag extends StatelessWidget {
  const _NodeTag({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: isSelected ? AppTheme.primary : const Color(0xCC3A3D44),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
