import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SizedBox(width: 320, child: child)),
);

void main() {
  const binding = BoundPropValue(
    source: BindingSourceIds.pageParam,
    path: 'nome',
  );

  testWidgets('mostra "Fonte · caminho"', (tester) async {
    await tester.pumpWidget(
      _host(BindingChip(binding: binding, onTap: () {}, onRemove: () {})),
    );

    final label = bindingSourceCatalog
        .firstWhere((s) => s.id == BindingSourceIds.pageParam)
        .label;
    expect(find.text('$label · nome'), findsOneWidget);
  });

  testWidgets('toque no texto chama onTap e o × chama onRemove', (
    tester,
  ) async {
    var taps = 0;
    var removes = 0;
    await tester.pumpWidget(
      _host(
        BindingChip(
          binding: binding,
          onTap: () => taps++,
          onRemove: () => removes++,
        ),
      ),
    );

    await tester.tap(find.textContaining('nome'));
    await tester.tap(find.byTooltip(BindingChip.removeLabel));

    expect(taps, 1);
    expect(removes, 1);
  });
}
