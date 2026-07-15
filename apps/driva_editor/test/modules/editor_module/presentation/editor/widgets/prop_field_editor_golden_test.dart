import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../support/golden.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await installTolerantGoldenComparator();
  });

  final cases = <({String name, PropField field, Object? value})>[
    (
      name: 'string',
      field: const PropField(
        key: 'data',
        kind: FieldKind.string,
        label: 'Texto',
        group: FieldGroups.content,
      ),
      value: 'Semana do cliente',
    ),
    (
      name: 'number',
      field: const PropField(
        key: 'fontSize',
        kind: FieldKind.doubleNum,
        label: 'Tamanho da fonte',
        group: FieldGroups.style,
      ),
      value: 16.0,
    ),
    (
      name: 'bool',
      field: const PropField(
        key: 'enabled',
        kind: FieldKind.boolean,
        label: 'Habilitado',
        group: FieldGroups.content,
      ),
      value: true,
    ),
    (
      name: 'color',
      field: const PropField(
        key: 'color',
        kind: FieldKind.color,
        label: 'Cor',
        group: FieldGroups.style,
      ),
      value: '#2F6BFF',
    ),
    (
      name: 'enum',
      field: const PropField(
        key: 'fontWeight',
        kind: FieldKind.enumeration,
        label: 'Peso da fonte',
        group: FieldGroups.style,
        enumValues: ['w400', 'w600', 'w700'],
      ),
      value: 'w600',
    ),
    (
      name: 'edge_insets',
      field: const PropField(
        key: 'padding',
        kind: FieldKind.edgeInsets,
        label: 'Padding',
        group: FieldGroups.spacing,
      ),
      value: const {'left': 8.0, 'top': 12.0, 'right': 8.0, 'bottom': 16.0},
    ),
    (
      name: 'alignment',
      field: const PropField(
        key: 'alignment',
        kind: FieldKind.alignment,
        label: 'Alinhamento do filho',
        group: FieldGroups.layout,
      ),
      value: 'center',
    ),
    (
      name: 'icon',
      field: const PropField(
        key: 'icon',
        kind: FieldKind.iconName,
        label: 'Ícone',
        group: FieldGroups.content,
      ),
      value: 'star',
    ),
  ];

  for (final c in cases) {
    testWidgets('golden: editor ${c.name}', (tester) async {
      tester.view.physicalSize = const Size(380, 340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: PropFieldEditor(
                  field: c.field,
                  value: c.value,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PropFieldEditor),
        matchesGoldenFile('goldens/prop_field_${c.name}.png'),
      );
    });
  }
}
