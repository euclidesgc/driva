import 'dart:ui' show Tristate;

import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/layout/panel_rail.dart';
import 'package:driva_editor/core/widgets/layout/panel_rail_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renderiza um botão por item da faixa', (tester) async {
    await tester.pumpWidget(
      _harness(
        PanelRail(
          items: [
            PanelRailButton(
              icon: Icons.widgets_outlined,
              label: 'Widgets',
              onPressed: () {},
            ),
            PanelRailButton(
              icon: Icons.account_tree_outlined,
              label: 'Árvore',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.byType(PanelRailButton), findsNWidgets(2));
    expect(find.byIcon(Icons.widgets_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_tree_outlined), findsOneWidget);
  });

  testWidgets('tocar um botão chama o callback certo', (tester) async {
    var widgetsTapped = 0;
    var treeTapped = 0;
    await tester.pumpWidget(
      _harness(
        PanelRail(
          items: [
            PanelRailButton(
              icon: Icons.widgets_outlined,
              label: 'Widgets',
              onPressed: () => widgetsTapped++,
            ),
            PanelRailButton(
              icon: Icons.account_tree_outlined,
              label: 'Árvore',
              onPressed: () => treeTapped++,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.account_tree_outlined));
    await tester.pump();

    expect(treeTapped, 1);
    expect(widgetsTapped, 0);
  });

  testWidgets('cada botão expõe tooltip como rótulo de acessibilidade', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        PanelRail(
          items: [
            PanelRailButton(
              icon: Icons.widgets_outlined,
              label: 'Widgets',
              onPressed: () {},
            ),
            PanelRailButton(
              icon: Icons.account_tree_outlined,
              label: 'Árvore',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.byTooltip('Widgets'), findsOneWidget);
    expect(find.byTooltip('Árvore'), findsOneWidget);
  });

  testWidgets(
    'o botão da aba corrente expõe Semantics(selected:) e o contorno, o '
    'resto não',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _harness(
          PanelRail(
            items: [
              PanelRailButton(
                icon: Icons.widgets_outlined,
                label: 'Widgets',
                isSelected: true,
                onPressed: () {},
              ),
              PanelRailButton(
                icon: Icons.account_tree_outlined,
                label: 'Árvore',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      final selectedFinder = find.widgetWithIcon(
        PanelRailButton,
        Icons.widgets_outlined,
      );
      final unselectedFinder = find.widgetWithIcon(
        PanelRailButton,
        Icons.account_tree_outlined,
      );

      expect(
        tester.getSemantics(selectedFinder).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(unselectedFinder).flagsCollection.isSelected,
        Tristate.isFalse,
      );

      final selectedDecoration =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: selectedFinder,
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      final unselectedDecoration =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: unselectedFinder,
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;

      expect(selectedDecoration.border, isNotNull);
      expect(unselectedDecoration.border, isNull);

      semantics.dispose();
    },
  );
}
