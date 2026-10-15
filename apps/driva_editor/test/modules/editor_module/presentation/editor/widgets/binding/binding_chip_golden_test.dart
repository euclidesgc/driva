import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../../support/golden.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await installTolerantGoldenComparator();
  });

  testWidgets('chip de campo ligado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: BindingChip(
                binding: const BoundPropValue(
                  source: BindingSourceIds.pageParam,
                  path: 'nome',
                ),
                onTap: () {},
                onRemove: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(BindingChip),
      matchesGoldenFile('goldens/binding_chip.png'),
    );
  });
}
