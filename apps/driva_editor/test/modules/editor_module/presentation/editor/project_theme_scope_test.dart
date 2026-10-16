import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/project_theme_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/version_compare_inert_preview.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_snapshot_preview.dart';
import 'package:driva_editor/modules/editor_module/presentation/preview/widgets/preview_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

void main() {
  const spec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(id: 'nd_root', type: 'column'),
  );
  final custom = ProjectTheme(
    colors: {...kDefaultProjectTheme.colors, ThemeColorRole.primary: '#FF0000'},
    textStyles: kDefaultProjectTheme.textStyles,
    radii: kDefaultProjectTheme.radii,
    shadows: kDefaultProjectTheme.shadows,
  );

  Future<void> pumpIn(WidgetTester tester, Widget child, {bool scope = true}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: scope
                ? ProjectThemeScope(theme: custom, child: child)
                : child,
          ),
        ),
      );

  testWidgets('sem escopo, of() devolve o tema padrão', (tester) async {
    late ProjectTheme got;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          got = ProjectThemeScope.of(c);
          return const SizedBox();
        },
      ),
    );
    expect(got, kDefaultProjectTheme);
  });

  testWidgets('prévia de versão repassa o tema do projeto ao SduiView', (
    tester,
  ) async {
    await pumpIn(tester, const VersionSnapshotPreview(spec: spec));
    expect(tester.widget<SduiView>(find.byType(SduiView)).theme, custom);
  });

  testWidgets('comparação de versões repassa o tema do projeto', (
    tester,
  ) async {
    await pumpIn(tester, const VersionCompareInertPreview(spec: spec));
    expect(tester.widget<SduiView>(find.byType(SduiView)).theme, custom);
  });

  testWidgets('prévia repassa o tema do projeto', (tester) async {
    await pumpIn(
      tester,
      PreviewContent(
        spec: spec,
        fetchedAt: DateTime(2026),
        onRefresh: () async {},
      ),
    );
    expect(tester.widget<SduiView>(find.byType(SduiView)).theme, custom);
  });
}
