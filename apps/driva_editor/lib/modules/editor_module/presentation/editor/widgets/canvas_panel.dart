import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/editor_colors.dart';
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
    final colors = Theme.of(context).extension<EditorColors>()!;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(bottom: BorderSide(color: colors.border)),
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
            style: TextStyle(fontSize: 12, color: colors.inkMuted),
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

/// Moldura realista do dispositivo: corpo metálico com bezel, cantos
/// arredondados, botões laterais e recorte de câmera (pill/punch-hole)
/// derivados do [DevicePreset]. Puramente visual — desenhada com
/// decorations/`CustomPaint`, sem dependência externa. A tela (a `child`) é
/// clipada com as dimensões e o raio de cantos do device.
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({
    required this.device,
    required this.highlighted,
    required this.child,
  });

  final DevicePreset device;
  final bool highlighted;
  final Widget child;

  static const _bodyColor = Color(0xFF1B1D21);
  static const _rimColor = Color(0xFF3A3D44);
  static const _buttonColor = Color(0xFF2A2D33);

  @override
  Widget build(BuildContext context) {
    final bezel = device.bezel;
    final bodyRadius = device.cornerRadius + bezel;
    final buttonWidth = bezel * 0.55;

    return Semantics(
      label:
          'Moldura ${device.label} (${device.width.toInt()}'
          '×${device.height.toInt()})',
      child: Padding(
        // Espaço para os botões laterais transbordarem o corpo.
        padding: EdgeInsets.symmetric(horizontal: buttonWidth),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _SideButton(
              alignment: Alignment.centerLeft,
              width: buttonWidth,
              color: _buttonColor,
              top: device.height * 0.20,
              length: device.height * 0.10,
            ),
            _SideButton(
              alignment: Alignment.centerRight,
              width: buttonWidth,
              color: _buttonColor,
              top: device.height * 0.16,
              length: device.height * 0.06,
            ),
            _SideButton(
              alignment: Alignment.centerRight,
              width: buttonWidth,
              color: _buttonColor,
              top: device.height * 0.26,
              length: device.height * 0.12,
            ),
            Container(
              padding: EdgeInsets.all(bezel),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF25282E), _bodyColor],
                ),
                borderRadius: BorderRadius.circular(bodyRadius),
                border: Border.all(color: _rimColor, width: 1),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 32,
                    offset: Offset(0, 16),
                  ),
                  if (highlighted)
                    const BoxShadow(
                      color: Color(0x66E8602C),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(device.cornerRadius),
                    child: SizedBox(
                      width: device.width,
                      height: device.height,
                      child: ColoredBox(color: Colors.white, child: child),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _CameraCutout(notch: device.notch),
                    ),
                  ),
                  if (highlighted)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              device.cornerRadius,
                            ),
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão físico lateral (power/volume) desenhado meio para fora do corpo.
class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.alignment,
    required this.width,
    required this.color,
    required this.top,
    required this.length,
  });

  final Alignment alignment;
  final double width;
  final Color color;
  final double top;
  final double length;

  @override
  Widget build(BuildContext context) {
    final left = alignment == Alignment.centerLeft;
    return Positioned(
      top: top,
      left: left ? -width / 2 : null,
      right: left ? null : -width / 2,
      child: Container(
        width: width,
        height: length,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.horizontal(
            left: left ? const Radius.circular(3) : Radius.zero,
            right: left ? Radius.zero : const Radius.circular(3),
          ),
        ),
      ),
    );
  }
}

/// Recorte da câmera sobre a tela: pill central ou furo pequeno (punch-hole).
class _CameraCutout extends StatelessWidget {
  const _CameraCutout({required this.notch});

  final DeviceNotch notch;

  static const _color = Color(0xFF0B0C0E);

  @override
  Widget build(BuildContext context) {
    return switch (notch) {
      DeviceNotch.pill => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: 90,
            height: 26,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ),
      DeviceNotch.punchHole => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    };
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

  /// Nó sob o cursor. Estado **efêmero e local do canvas**: não vai ao cubit
  /// (não rebuilda o editor inteiro nem persiste), só realça o contorno.
  String? _hoveredNodeId;
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
    final root = document.root;
    final isEmpty = root == null || root.children.isEmpty;
    return GestureDetector(
      // Clique no vazio limpa a seleção (volta às propriedades do conteúdo).
      onTap: () => widget.onSelect(null),
      child: isEmpty
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
                  isHovered: node.id == _hoveredNodeId,
                  onSelect: () => widget.onSelect(node.id),
                  onHover: (hovering) {
                    if (!mounted) return;
                    final id = hovering ? node.id : null;
                    if (hovering && _hoveredNodeId == node.id) return;
                    if (!hovering && _hoveredNodeId != node.id) return;
                    setState(() => _hoveredNodeId = id);
                  },
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
    // Este hint fica sobre a tela BRANCA do dispositivo (superfície do app
    // previsto), não sobre os painéis do editor — usa a paleta clara fixa para
    // manter contraste AA mesmo com o editor no tema escuro. A moldura tracejada
    // convida a soltar/clicar o primeiro widget (que vira a raiz).
    const colors = EditorColors.light;
    return Semantics(
      label: 'Conteúdo vazio. Adicione o primeiro widget.',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CustomPaint(
            foregroundPainter: DashedBorderPainter(color: colors.border),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_box_outlined,
                    size: 40,
                    color: colors.inkMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Arraste um widget aqui ou clique num widget da '
                    'paleta para começar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.inkSecondary),
                  ),
                ],
              ),
            ),
          ),
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
    required this.isHovered,
    required this.onSelect,
    required this.onHover,
  });

  final SduiNode node;
  final Widget built;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onSelect;
  final ValueChanged<bool> onHover;

  static const _unwrappable = {'spacer'};
  static const _hintColor = Color(0x66A0A4AD);

  /// Contorno de hover: laranja da marca com opacidade baixa — reforço leve,
  /// abaixo da seleção sólida na precedência. A tag/nome continuam sendo o
  /// sinal permanente (o hover não é o único indicador).
  static final _hoverColor = AppTheme.primary.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    if (_unwrappable.contains(node.type)) return built;

    final descriptor = descriptorFor(node.type);
    final label = descriptor?.label ?? node.type;
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
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
              else if (isHovered)
                DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    border: Border.all(color: _hoverColor, width: 1.5),
                  ),
                  child: built,
                )
              else
                CustomPaint(
                  foregroundPainter: const DashedBorderPainter(
                    color: _hintColor,
                  ),
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
