import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/panel_collapse_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('onCollapse null (sem EditorLayoutScope acima) some em vez de '
      'crashar', (tester) async {
    await tester.pumpWidget(
      _harness(
        const PanelCollapseButton(
          icon: Icons.chevron_left,
          label: 'Recolher painel',
          onCollapse: null,
        ),
      ),
    );

    expect(find.byType(IconButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onCollapse presente renderiza o botão com tooltip e ícone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        PanelCollapseButton(
          icon: Icons.chevron_left,
          label: 'Recolher painel',
          onCollapse: () {},
        ),
      ),
    );

    expect(find.byTooltip('Recolher painel'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
  });

  testWidgets('tocar o botão chama onCollapse', (tester) async {
    var collapsed = 0;
    await tester.pumpWidget(
      _harness(
        PanelCollapseButton(
          icon: Icons.chevron_left,
          label: 'Recolher painel',
          onCollapse: () => collapsed++,
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(collapsed, 1);
  });
}
