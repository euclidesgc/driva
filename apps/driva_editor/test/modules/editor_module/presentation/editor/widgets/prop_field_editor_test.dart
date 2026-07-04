import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

/// Reproduz o fluxo real do Inspector: o valor editado volta pelo `onChanged`
/// e o pai reconstrói o `PropFieldEditor` com a MESMA key de identidade
/// (`nodeId_fieldKey`). O bug de foco acontecia quando o campo era recriado a
/// cada tecla; aqui garantimos que ele sobrevive ao rebuild.
class _InspectorHarness extends StatefulWidget {
  const _InspectorHarness({required this.field});

  final PropField field;

  @override
  State<_InspectorHarness> createState() => _InspectorHarnessState();
}

class _InspectorHarnessState extends State<_InspectorHarness> {
  Object? _value;
  Object? lastEmitted;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PropFieldEditor(
          key: ValueKey('node-1_${widget.field.key}'),
          field: widget.field,
          value: _value,
          onChanged: (value) {
            lastEmitted = value;
            setState(() => _value = value);
          },
        ),
      ),
    );
  }
}

void main() {
  group('PropFieldEditor · foco preservado ao digitar', () {
    testWidgets('campo numérico não é recriado quando o valor volta', (
      tester,
    ) async {
      const field = PropField(
        key: 'elevation',
        kind: FieldKind.intNum,
        label: 'Elevação',
        group: FieldGroups.style,
      );
      await tester.pumpWidget(const _InspectorHarness(field: field));

      final before = tester.state<EditableTextState>(find.byType(EditableText));
      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();
      final after = tester.state<EditableTextState>(find.byType(EditableText));

      expect(identical(before, after), isTrue);
      expect(after.widget.focusNode.hasFocus, isTrue);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('valor numérico digitado é emitido tipado', (tester) async {
      const field = PropField(
        key: 'elevation',
        kind: FieldKind.intNum,
        label: 'Elevação',
        group: FieldGroups.style,
      );
      final harness = _InspectorHarness(field: field);
      await tester.pumpWidget(harness);

      await tester.enterText(find.byType(TextField), '10');
      await tester.pump();

      final state = tester.state<_InspectorHarnessState>(
        find.byType(_InspectorHarness),
      );
      expect(state.lastEmitted, 10);
    });

    testWidgets('campo de texto não é recriado quando o valor volta', (
      tester,
    ) async {
      const field = PropField(
        key: 'text',
        kind: FieldKind.string,
        label: 'Texto',
        group: FieldGroups.content,
      );
      await tester.pumpWidget(const _InspectorHarness(field: field));

      final before = tester.state<EditableTextState>(find.byType(EditableText));
      await tester.enterText(find.byType(TextField), 'Olá');
      await tester.pump();
      final after = tester.state<EditableTextState>(find.byType(EditableText));

      expect(identical(before, after), isTrue);
      expect(after.widget.focusNode.hasFocus, isTrue);
      expect(find.text('Olá'), findsOneWidget);
    });

    testWidgets('trocar de nó (key diferente) reinicia o campo com o valor', (
      tester,
    ) async {
      const field = PropField(
        key: 'text',
        kind: FieldKind.string,
        label: 'Texto',
        group: FieldGroups.content,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropFieldEditor(
              key: const ValueKey('node-A_text'),
              field: field,
              value: 'A',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropFieldEditor(
              key: const ValueKey('node-B_text'),
              field: field,
              value: 'B',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('B'), findsOneWidget);
      expect(find.text('A'), findsNothing);
    });
  });
}
