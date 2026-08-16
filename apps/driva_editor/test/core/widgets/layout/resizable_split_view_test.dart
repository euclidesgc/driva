import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/layout/resizable_split_view.dart';
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
}
