import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_compare_enums.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_diff_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, VersionCompareMarkerKind kind) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: TreeRowDiffMarker(kind: kind)),
    ),
  );
}

Icon _icon(WidgetTester tester) => tester.widget<Icon>(find.byType(Icon));

void main() {
  const kinds = {
    VersionCompareMarkerKind.propertiesChanged: 'Propriedades alteradas',
    VersionCompareMarkerKind.onlyInBase: 'Somente no rascunho',
    VersionCompareMarkerKind.onlyInCandidate: 'Somente na versão',
    VersionCompareMarkerKind.typeChanged: 'Tipo mudou',
  };

  for (final MapEntry(key: kind, value: label) in kinds.entries) {
    testWidgets('$label aparece como tooltip e rótulo semântico', (
      tester,
    ) async {
      await _pump(tester, kind);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, label);
      expect(_icon(tester).semanticLabel, label);
    });
  }

  testWidgets('cada um dos quatro marcadores tem um ícone distinto', (
    tester,
  ) async {
    final icons = <IconData>{};
    for (final kind in kinds.keys) {
      await _pump(tester, kind);
      icons.add(_icon(tester).icon!);
    }

    expect(icons, hasLength(4));
  });

  testWidgets('marcador somente leitura declara isso no tooltip', (
    tester,
  ) async {
    await _pump(tester, VersionCompareMarkerKind.safeAreaChanged);

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(
      tooltip.message,
      'Safe area alterada — somente leitura nesta versão do Driva',
    );
  });
}
