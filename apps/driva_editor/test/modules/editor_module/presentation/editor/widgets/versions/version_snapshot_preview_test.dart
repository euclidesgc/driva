import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_snapshot_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  const spec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(
      id: 'nd_root',
      type: 'column',
      children: [
        SduiNode(
          id: 'nd_field',
          type: 'textField',
          properties: {'label': 'Nome', 'value': 'original'},
        ),
      ],
    ),
  );

  Future<void> pumpSnapshot(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: VersionSnapshotPreview(spec: spec)),
    ),
  );

  testWidgets(
    'mecanismo: o snapshot fica dentro de AbsorbPointer(absorbing: true) e '
    'FocusScope(canRequestFocus: false)',
    (tester) async {
      await pumpSnapshot(tester);

      final absorb = tester.widget<AbsorbPointer>(
        find.descendant(
          of: find.byType(VersionSnapshotPreview),
          matching: find.byType(AbsorbPointer),
        ),
      );
      expect(absorb.absorbing, isTrue);

      final scope = tester.widget<FocusScope>(
        find.descendant(
          of: find.byType(VersionSnapshotPreview),
          matching: find.byType(FocusScope),
        ),
      );
      expect(scope.canRequestFocus, isFalse);
    },
  );

  testWidgets('toque não foca o campo do snapshot', (tester) async {
    await pumpSnapshot(tester);

    final editable = tester.state<EditableTextState>(
      find.byType(EditableText),
    );
    expect(editable.widget.focusNode.hasFocus, isFalse);

    await tester.tap(find.byType(TextFormField), warnIfMissed: false);
    await tester.pump();

    expect(editable.widget.focusNode.hasFocus, isFalse);
  });

  testWidgets('Tab não move o foco para dentro do snapshot', (tester) async {
    final anchorFocus = FocusNode();
    addTearDown(anchorFocus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: anchorFocus, autofocus: true),
              const VersionSnapshotPreview(spec: spec),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(anchorFocus.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final editable = tester.state<EditableTextState>(
      find.byType(EditableText).last,
    );
    expect(editable.widget.focusNode.hasFocus, isFalse);
    expect(anchorFocus.hasFocus, isTrue);
  });

  testWidgets('digitação não altera o valor do campo do snapshot', (
    tester,
  ) async {
    await pumpSnapshot(tester);

    await tester.enterText(find.byType(TextFormField), 'texto invasor');
    await tester.pump();

    expect(find.text('texto invasor'), findsNothing);
    expect(find.text('original'), findsOneWidget);
  });
}
