import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/widget_tree.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  const root = SduiNode(
    id: 'root',
    type: 'column',
    children: [
      SduiNode(id: 'text', type: 'text'),
      SduiNode(id: 'button', type: 'button'),
    ],
  );

  NodeDiff diffOf(
    String id, {
    String baseType = 'text',
    String candidateType = 'text',
    bool propertiesChanged = false,
    bool eventsChanged = false,
  }) => NodeDiff(
    nodeId: id,
    baseType: baseType,
    candidateType: candidateType,
    propertiesChanged: propertiesChanged,
    eventsChanged: eventsChanged,
    childOrderChanged: false,
    baseParentId: null,
    candidateParentId: null,
  );

  Widget harness({
    Map<String, NodeDiff> compareDiffs = const {},
    Set<String> compareOnlyInBase = const {},
    List<SduiNode> compareGhostNodes = const [],
    List<VersionCompareMarkerKind> pageDiffMarkers = const [],
    Map<String, List<SpecDiagnostic>> nodeDiagnostics = const {},
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: WidgetTreePanel(
          root: root,
          selectedNodeId: null,
          nodeDiagnostics: nodeDiagnostics,
          compareDiffs: compareDiffs,
          compareOnlyInBase: compareOnlyInBase,
          compareGhostNodes: compareGhostNodes,
          pageDiffMarkers: pageDiffMarkers,
          onSelect: (_) {},
          onRemove: (_) {},
          onDropNew: (_, _) {},
          onDropMove: (_, _) {},
          onDropNewAt: (_, _, _) {},
          onDropMoveAt: (_, _, _) {},
        ),
      ),
    );
  }

  Set<VersionCompareMarkerKind> markerKinds(WidgetTester tester) => tester
      .widgetList<TreeRowDiffMarker>(find.byType(TreeRowDiffMarker))
      .map((marker) => marker.kind)
      .toSet();

  testWidgets('fora do modo, nenhuma linha tem marcador', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byType(TreeRowDiffMarker), findsNothing);
  });

  testWidgets(
    'nó alterado, nó só no rascunho e nó com tipo mudado, cada um com seu '
    'marcador',
    (tester) async {
      await tester.pumpWidget(
        harness(
          compareDiffs: {
            'text': diffOf('text', propertiesChanged: true),
            'button': diffOf(
              'button',
              baseType: 'button',
            ),
          },
          compareOnlyInBase: const {'root'},
        ),
      );

      expect(markerKinds(tester), {
        VersionCompareMarkerKind.propertiesChanged,
        VersionCompareMarkerKind.typeChanged,
        VersionCompareMarkerKind.onlyInBase,
      });
    },
  );

  testWidgets('nó só na versão vira linha-fantasma somente leitura', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        compareGhostNodes: const [SduiNode(id: 'ghost', type: 'spacer')],
      ),
    );

    final ghostRow = find.byType(CompareGhostTreeRow);
    expect(ghostRow, findsOneWidget);
    final marker = tester.widget<TreeRowDiffMarker>(
      find.descendant(of: ghostRow, matching: find.byType(TreeRowDiffMarker)),
    );
    expect(marker.kind, VersionCompareMarkerKind.onlyInCandidate);
    expect(
      find.descendant(of: ghostRow, matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  testWidgets('marcador de diff e diagnóstico convivem na mesma linha', (
    tester,
  ) async {
    const aviso = SpecDiagnostic(
      nodeId: 'text',
      nodeType: 'text',
      code: DiagnosticCode.emptySingleSlot,
      severity: DiagnosticSeverity.warning,
      message: 'Aviso de teste.',
    );
    await tester.pumpWidget(
      harness(
        compareDiffs: {'text': diffOf('text', propertiesChanged: true)},
        nodeDiagnostics: const {
          'text': [aviso],
        },
      ),
    );

    final row = find.ancestor(
      of: find.byType(TreeRowDiagnosticIcon),
      matching: find.byType(TreeRowContent),
    );
    expect(
      find.descendant(of: row, matching: find.byType(TreeRowDiffMarker)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.byType(TreeRowDiagnosticIcon)),
      findsOneWidget,
    );
  });

  group('linha da página', () {
    testWidgets('mostra marcador quando a safe area mudou', (tester) async {
      await tester.pumpWidget(
        harness(
          pageDiffMarkers: const [VersionCompareMarkerKind.safeAreaChanged],
        ),
      );

      final marker = tester.widget<TreeRowDiffMarker>(
        find.descendant(
          of: find.byType(PageTreeRow),
          matching: find.byType(TreeRowDiffMarker),
        ),
      );
      expect(marker.kind, VersionCompareMarkerKind.safeAreaChanged);
    });

    testWidgets('não mostra marcador quando a safe area não mudou', (
      tester,
    ) async {
      await tester.pumpWidget(harness());

      expect(
        find.descendant(
          of: find.byType(PageTreeRow),
          matching: find.byType(TreeRowDiffMarker),
        ),
        findsNothing,
      );
    });
  });
}
