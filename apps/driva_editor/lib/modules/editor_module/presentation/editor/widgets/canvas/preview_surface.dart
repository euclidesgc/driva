import 'dart:async';

import 'package:driva_editor/core/theme/app_durations.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/empty_preview.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/selectable_node.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/drag_payload.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/node_diagnostics_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// Throttla o re-render do documento: o renderer real é caro a cada tecla.
class PreviewSurface extends StatefulWidget {
  const PreviewSurface({
    required this.onSelect,
    required this.onDropOn,
    super.key,
  });

  final ValueChanged<String?> onSelect;

  /// Payload solto sobre o nó de id `targetId`; quem decide onde ele encaixa
  /// de fato é o kernel, pelo cubit.
  final void Function(DragPayload payload, String targetId) onDropOn;

  @override
  State<PreviewSurface> createState() => _PreviewSurfaceState();
}

class _PreviewSurfaceState extends State<PreviewSurface> {
  static const Duration _throttle = AppDurations.micro;

  late final EditorCubit _cubit = context.read<EditorCubit>();
  late StreamSubscription<EditorState> _subscription;

  late ContentSpec _rendered;
  String? _selectedNodeId;
  Map<String, List<SpecDiagnostic>> _nodeDiagnostics = const {};

  String? _hoveredNodeId;
  Timer? _cooldown;
  bool _pendingRender = false;

  @override
  void initState() {
    super.initState();
    final state = _cubit.state as EditorReady;
    _rendered = state.document;
    _selectedNodeId = state.selectedNodeId;
    _nodeDiagnostics = diagnosticsByNode(diagnoseTree(_rendered.root));
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
    setState(() {
      _rendered = state.document;
      _nodeDiagnostics = diagnosticsByNode(diagnoseTree(_rendered.root));
    });
    _pendingRender = false;
    _cooldown = Timer(_throttle, () {
      if (_pendingRender && mounted) _applyDocument();
    });
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    _cooldown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = _rendered;
    final root = document.root;
    final isEmpty = root == null;
    return GestureDetector(
      onTap: () => widget.onSelect(null),
      child: isEmpty
          ? const EmptyPreview()
          : SingleChildScrollView(
              child: SduiView.content(
                document,
                onAction: (action) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ação "${action.type}" é executada só no app cliente.',
                      ),
                    ),
                  );
                },
                nodeWrapper: (node, built) => SelectableNode(
                  node: node,
                  built: built,
                  isSelected: node.id == _selectedNodeId,
                  isHovered: node.id == _hoveredNodeId,
                  diagnostics: _nodeDiagnostics[node.id] ?? const [],
                  onSelect: () => widget.onSelect(node.id),
                  onAccept: (payload) => widget.onDropOn(payload, node.id),
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
