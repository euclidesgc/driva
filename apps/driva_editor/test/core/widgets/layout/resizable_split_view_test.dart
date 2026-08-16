import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/layout/panel_rail.dart';
import 'package:driva_editor/core/widgets/layout/panel_rail_button.dart';
import 'package:driva_editor/core/widgets/layout/resizable_split_view.dart';
import 'package:driva_editor/core/widgets/layout/resize_handle.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _harness = MaterialApp(
  theme: AppTheme.light,
  home: const ResizableSplitView(
    left: ColoredBox(color: Colors.red),
    center: ColoredBox(color: Colors.green),
    right: ColoredBox(color: Colors.blue),
  ),
);

class _BuildCounter extends StatelessWidget {
  const _BuildCounter({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const SizedBox.shrink();
  }
}

Widget _controlledHarness({
  required EditorLayoutController controller,
  required Widget left,
  required Widget center,
  required Widget right,
  ValueChanged<double>? onLeftWidthChanged,
  ValueChanged<double>? onRightWidthChanged,
}) => MaterialApp(
  theme: AppTheme.light,
  home: ResizableSplitView(
    left: left,
    leftPanelRail: const PanelRail(
      items: [
        PanelRailButton(
          icon: Icons.widgets_outlined,
          label: 'Widgets',
          onPressed: _noop,
        ),
      ],
    ),
    center: center,
    right: right,
    rightPanelRail: const PanelRail(
      items: [
        PanelRailButton(icon: Icons.tune, label: 'Inspector', onPressed: _noop),
      ],
    ),
    layoutListenable: controller,
    isLeftCollapsed: () => controller.value.leftPanelCollapsed,
    isRightCollapsed: () => controller.value.rightPanelCollapsed,
    onLeftWidthChanged: onLeftWidthChanged,
    onRightWidthChanged: onRightWidthChanged,
  ),
);

void _noop() {}

Finder _horizontalScrollFinder() => find.byWidgetPredicate(
  (widget) =>
      widget is SingleChildScrollView &&
      widget.scrollDirection == Axis.horizontal,
);

Future<void> _pumpAtWidth(WidgetTester tester, double width) async {
  await tester.binding.setSurfaceSize(Size(width, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_harness);
  await tester.pump();
}

Future<void> _pumpControlledAtWidth(
  WidgetTester tester,
  double width,
  EditorLayoutController controller,
) async {
  await tester.binding.setSurfaceSize(Size(width, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _controlledHarness(
      controller: controller,
      left: const ColoredBox(color: Colors.red),
      center: const ColoredBox(color: Colors.green),
      right: const ColoredBox(color: Colors.blue),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'abaixo do piso mecânico do workspace (D14), o ResizableSplitView rola '
    'na horizontal em vez de encolher os painéis',
    (tester) async {
      await _pumpAtWidth(tester, AppSizes.workspaceMinimumWidth - 1);

      expect(_horizontalScrollFinder(), findsOneWidget);
    },
  );

  testWidgets(
    'exatamente no piso mecânico do workspace (D14), o ResizableSplitView '
    'não rola',
    (tester) async {
      await _pumpAtWidth(tester, AppSizes.workspaceMinimumWidth);

      expect(_horizontalScrollFinder(), findsNothing);
    },
  );

  testWidgets(
    'acima do piso mecânico do workspace (D14), o ResizableSplitView não '
    'rola',
    (tester) async {
      await _pumpAtWidth(tester, AppSizes.workspaceMinimumWidth + 100);

      expect(_horizontalScrollFinder(), findsNothing);
    },
  );

  group('sem EditorLayoutScope acima (não controlado)', () {
    testWidgets('nunca renderiza um PanelRail', (tester) async {
      await tester.pumpWidget(_harness);
      await tester.pump();

      expect(find.byType(PanelRail), findsNothing);
    });
  });

  group('controlado por EditorLayoutScope (D2, D7)', () {
    late EditorLayoutController controller;

    setUp(() => controller = EditorLayoutController());
    tearDown(() => controller.dispose());

    testWidgets(
      'leftPanelCollapsed=true renderiza o leftPanelRail no lugar do left',
      (tester) async {
        controller.collapseLeftPanel();
        await tester.pumpWidget(
          _controlledHarness(
            controller: controller,
            left: const ColoredBox(color: Colors.red),
            center: const ColoredBox(color: Colors.green),
            right: const ColoredBox(color: Colors.blue),
          ),
        );
        await tester.pump();

        expect(find.byType(PanelRail), findsOneWidget);
        expect(find.byTooltip('Widgets'), findsOneWidget);
      },
    );

    testWidgets(
      'D14 — painel esquerdo colapsado: um pixel abaixo do piso de painel '
      'cheio ainda não rola, porque o piso caiu para panelRailWidth',
      (tester) async {
        controller.collapseLeftPanel();
        await _pumpControlledAtWidth(
          tester,
          AppSizes.workspaceMinimumWidth - 1,
          controller,
        );

        expect(_horizontalScrollFinder(), findsNothing);
      },
    );

    testWidgets(
      'D14 — o mesmo painel esquerdo expandido, na mesma largura, ainda '
      'rola: foi o colapso que mudou o piso, não a largura',
      (tester) async {
        await _pumpControlledAtWidth(
          tester,
          AppSizes.workspaceMinimumWidth - 1,
          controller,
        );

        expect(_horizontalScrollFinder(), findsOneWidget);
      },
    );

    testWidgets(
      'os dois lados colapsados renderizam duas faixas, sem painel cheio',
      (tester) async {
        controller
          ..collapseLeftPanel()
          ..collapseRightPanel();
        await tester.pumpWidget(
          _controlledHarness(
            controller: controller,
            left: const ColoredBox(color: Colors.red),
            center: const ColoredBox(color: Colors.green),
            right: const ColoredBox(color: Colors.blue),
          ),
        );
        await tester.pump();

        expect(find.byType(PanelRail), findsNWidgets(2));
        expect(find.byTooltip('Widgets'), findsOneWidget);
        expect(find.byTooltip('Inspector'), findsOneWidget);
      },
    );

    testWidgets('colapsar e reexpandir volta a mostrar o painel cheio', (
      tester,
    ) async {
      await tester.pumpWidget(
        _controlledHarness(
          controller: controller,
          left: const ColoredBox(color: Colors.red),
          center: const ColoredBox(color: Colors.green),
          right: const ColoredBox(color: Colors.blue),
        ),
      );
      await tester.pump();
      expect(find.byType(PanelRail), findsNothing);

      controller.collapseLeftPanel();
      await tester.pump();
      expect(find.byType(PanelRail), findsOneWidget);

      controller.expandLeftPanel();
      await tester.pump();
      expect(find.byType(PanelRail), findsNothing);
    });

    testWidgets(
      'D8 — trocar a aba do painel esquerdo não reconstrói left/center/right',
      (tester) async {
        var leftBuilds = 0;
        var centerBuilds = 0;
        var rightBuilds = 0;

        await tester.pumpWidget(
          _controlledHarness(
            controller: controller,
            left: _BuildCounter(onBuild: () => leftBuilds++),
            center: _BuildCounter(onBuild: () => centerBuilds++),
            right: _BuildCounter(onBuild: () => rightBuilds++),
          ),
        );
        await tester.pump();
        expect(leftBuilds, 1);
        expect(centerBuilds, 1);
        expect(rightBuilds, 1);

        controller.setLeftPanelTab(LeftPanelTab.tree);
        await tester.pump();
        controller.setLeftPanelTab(LeftPanelTab.widgets);
        await tester.pump();

        expect(leftBuilds, 1);
        expect(centerBuilds, 1);
        expect(rightBuilds, 1);
      },
    );

    testWidgets(
      'D8 — colapsar o painel direito não reconstrói left/center, que '
      'seguem montados',
      (tester) async {
        var leftBuilds = 0;
        var centerBuilds = 0;

        await tester.pumpWidget(
          _controlledHarness(
            controller: controller,
            left: _BuildCounter(onBuild: () => leftBuilds++),
            center: _BuildCounter(onBuild: () => centerBuilds++),
            right: const ColoredBox(color: Colors.blue),
          ),
        );
        await tester.pump();
        expect(leftBuilds, 1);
        expect(centerBuilds, 1);

        controller.collapseRightPanel();
        await tester.pump();
        controller.expandRightPanel();
        await tester.pump();

        expect(leftBuilds, 1);
        expect(centerBuilds, 1);
      },
    );

    testWidgets(
      'arrastar o handle esquerdo chama onLeftWidthChanged com a largura '
      'já clampada (F6)',
      (tester) async {
        final reported = <double>[];
        await tester.pumpWidget(
          _controlledHarness(
            controller: controller,
            left: const ColoredBox(color: Colors.red),
            center: const ColoredBox(color: Colors.green),
            right: const ColoredBox(color: Colors.blue),
            onLeftWidthChanged: reported.add,
          ),
        );
        await tester.pump();

        await tester.drag(find.byType(ResizeHandle).first, const Offset(40, 0));
        await tester.pump();

        expect(reported, isNotEmpty);
        expect(reported.last, inInclusiveRange(200, 480));
      },
    );

    testWidgets(
      'arrastar o handle direito chama onRightWidthChanged, e não o '
      'esquerdo',
      (tester) async {
        final leftReports = <double>[];
        final rightReports = <double>[];
        await tester.pumpWidget(
          _controlledHarness(
            controller: controller,
            left: const ColoredBox(color: Colors.red),
            center: const ColoredBox(color: Colors.green),
            right: const ColoredBox(color: Colors.blue),
            onLeftWidthChanged: leftReports.add,
            onRightWidthChanged: rightReports.add,
          ),
        );
        await tester.pump();

        await tester.drag(find.byType(ResizeHandle).last, const Offset(-40, 0));
        await tester.pump();

        expect(rightReports, isNotEmpty);
        expect(leftReports, isEmpty);
      },
    );
  });
}
