import 'dart:math' as math;

import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/widgets/layout/resize_handle.dart';
import 'package:flutter/material.dart';

class ResizableSplitView extends StatefulWidget {
  const ResizableSplitView({
    required this.left,
    required this.center,
    required this.right,
    super.key,
    this.leftPanelRail,
    this.rightPanelRail,
    this.layoutListenable,
    this.isLeftCollapsed,
    this.isRightCollapsed,
    this.initialLeftWidth = 280,
    this.initialRightWidth = 320,
    this.minPanelWidth = AppSizes.workspacePanelMinWidth,
    this.maxPanelWidth = 480,
    this.minCenterWidth = AppSizes.minCenterWidth,
  });

  final Widget left;
  final Widget center;
  final Widget right;

  /// Renderizado no lugar de [left]/[right] quando [isLeftCollapsed]/
  /// [isRightCollapsed] marcam aquele lado colapsado (D2) — na prática,
  /// sempre um `PanelRail`, mas `Widget` para este widget não precisar
  /// conhecer o tipo concreto. `null` = o lado correspondente nunca colapsa —
  /// é o que mantém o teste que monta este widget sozinho, sem nenhum dos
  /// três parâmetros de controle abaixo, funcionando como antes da F5.
  final Widget? leftPanelRail;
  final Widget? rightPanelRail;

  /// Dispara rebuild quando o estado de colapso muda. Tipo genérico
  /// (`Listenable`, de `package:flutter/foundation.dart`) de propósito: quem
  /// controla o colapso hoje é o `EditorLayoutController` do `editor_module`,
  /// mas este widget mora em `core/widgets/` — tier reutilizável por
  /// qualquer módulo — e não pode importar um módulo específico para saber
  /// disso.
  final Listenable? layoutListenable;

  /// Lidas a cada rebuild disparado por [layoutListenable] — nunca cacheadas
  /// — para refletir o estado de colapso corrente sem este widget conhecer
  /// onde ele mora.
  final bool Function()? isLeftCollapsed;
  final bool Function()? isRightCollapsed;

  final double initialLeftWidth;
  final double initialRightWidth;
  final double minPanelWidth;
  final double maxPanelWidth;
  final double minCenterWidth;

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  late double _leftWidth = widget.initialLeftWidth;
  late double _rightWidth = widget.initialRightWidth;

  /// Alimenta o `ListenableBuilder` quando
  /// [ResizableSplitView.layoutListenable] não é passado (o cenário do teste
  /// isolado) — nunca dispara, então `isLeftCollapsed`/`isRightCollapsed`
  /// caem no `?? false` de qualquer forma, e os dois lados nunca colapsam.
  final ChangeNotifier _uncontrolledNotifier = ChangeNotifier();

  double _clamp(double value) =>
      value.clamp(widget.minPanelWidth, widget.maxPanelWidth);

  @override
  void dispose() {
    _uncontrolledNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // D8: o `ListenableBuilder` fica aqui dentro, escopado à montagem da
        // `Row` — nunca em `EditorWorkspace.build`, que reconstruiria
        // `LeftPanel`/`CenterArea`/`InspectorArea` a cada clique no
        // controller.
        return ListenableBuilder(
          listenable: widget.layoutListenable ?? _uncontrolledNotifier,
          builder: (context, _) {
            final leftCollapsed =
                (widget.isLeftCollapsed?.call() ?? false) &&
                widget.leftPanelRail != null;
            final rightCollapsed =
                (widget.isRightCollapsed?.call() ?? false) &&
                widget.rightPanelRail != null;

            // D14 convivendo com a F5: um lado colapsado vira faixa fina, bem
            // mais estreita que `minPanelWidth` — o piso mecânico precisa da
            // largura real de cada lado (painel OU faixa), não sempre do
            // mínimo do painel cheio.
            const handleWidth = AppSizes.workspaceDividersWidth / 2;
            final leftDivider = leftCollapsed ? 0.0 : handleWidth;
            final rightDivider = rightCollapsed ? 0.0 : handleWidth;
            final dividers = leftDivider + rightDivider;

            final leftFloor = leftCollapsed
                ? AppSizes.panelRailWidth
                : widget.minPanelWidth;
            final rightFloor = rightCollapsed
                ? AppSizes.panelRailWidth
                : widget.minPanelWidth;
            final floor =
                leftFloor + rightFloor + dividers + widget.minCenterWidth;

            final leftStored = leftCollapsed
                ? AppSizes.panelRailWidth
                : _leftWidth;
            final rightStored = rightCollapsed
                ? AppSizes.panelRailWidth
                : _rightWidth;
            final storedRequirement =
                leftStored + rightStored + dividers + widget.minCenterWidth;
            final storedWidthsFit = constraints.maxWidth >= storedRequirement;

            final leftWidth = leftCollapsed
                ? AppSizes.panelRailWidth
                : (storedWidthsFit ? _leftWidth : widget.minPanelWidth);
            final rightWidth = rightCollapsed
                ? AppSizes.panelRailWidth
                : (storedWidthsFit ? _rightWidth : widget.minPanelWidth);

            final row = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leftCollapsed)
                  widget.leftPanelRail!
                else
                  SizedBox(width: leftWidth, child: widget.left),
                if (!leftCollapsed)
                  ResizeHandle(
                    onDrag: (dx) =>
                        setState(() => _leftWidth = _clamp(leftWidth + dx)),
                  ),
                Expanded(child: widget.center),
                if (!rightCollapsed)
                  ResizeHandle(
                    onDrag: (dx) =>
                        setState(() => _rightWidth = _clamp(rightWidth - dx)),
                  ),
                if (rightCollapsed)
                  widget.rightPanelRail!
                else
                  SizedBox(width: rightWidth, child: widget.right),
              ],
            );

            final rowWidth = math.max(constraints.maxWidth, floor);
            if (rowWidth <= constraints.maxWidth) {
              return row;
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: rowWidth, child: row),
            );
          },
        );
      },
    );
  }
}
