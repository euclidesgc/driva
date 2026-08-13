import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _alinhamento = PropField(
  key: 'alignment',
  kind: FieldKind.alignment,
  label: 'Alinhamento do filho',
  group: FieldGroups.layout,
);

class _Harness extends StatefulWidget {
  const _Harness({
    required this.initial,
    required this.changes,
    required this.field,
  });

  final Object? initial;
  final List<Object?> changes;
  final PropField field;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late Object? _value = widget.initial;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SizedBox(
        width: 360,
        child: AlignmentEditor(
          field: widget.field,
          value: _value,
          onChanged: (value) {
            widget.changes.add(value);
            setState(() => _value = value);
          },
        ),
      ),
    ),
  );
}

Future<List<Object?>> _pumpEditor(
  WidgetTester tester, {
  Object? value,
  PropField field = _alinhamento,
}) async {
  final changes = <Object?>[];
  await tester.pumpWidget(
    _Harness(initial: value, changes: changes, field: field),
  );
  return changes;
}

Finder _cell(String label) => find.byTooltip(label);

bool _isCellSelected(WidgetTester tester, String label) {
  final dot = tester.widget<Icon>(
    find.descendant(of: _cell(label), matching: find.byType(Icon)),
  );
  return dot.color == AppTheme.primary;
}

Finder _axisField(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(AlignmentAxisField),
);

TextEditingController _controllerOf(WidgetTester tester, String label) => tester
    .widget<TextField>(
      find.descendant(of: _axisField(label), matching: find.byType(TextField)),
    )
    .controller!;

void main() {
  group('grade', () {
    testWidgets('clicar numa célula emite o nome do preset', (tester) async {
      final changes = await _pumpEditor(tester);

      await tester.tap(_cell('Meio direito'));
      await tester.pump();

      expect(changes, ['centerRight']);
    });

    testWidgets('a célula do valor atual aparece selecionada', (tester) async {
      await _pumpEditor(tester, value: 'topLeft');

      expect(_isCellSelected(tester, 'Superior esquerdo'), isTrue);
      expect(_isCellSelected(tester, 'Centro'), isFalse);
    });

    testWidgets('valor fora da faixa não acende nenhuma célula', (
      tester,
    ) async {
      await _pumpEditor(tester, value: {'x': 10, 'y': 0});

      for (final label in AlignmentGrid.cellLabels) {
        expect(_isCellSelected(tester, label), isFalse, reason: label);
      }
    });

    testWidgets('reclicar a célula acesa limpa o valor', (tester) async {
      final changes = await _pumpEditor(tester, value: 'center');

      await tester.tap(_cell('Centro'));
      await tester.pump();

      expect(changes, [null]);
    });

    testWidgets('campo obrigatório não é limpo ao reclicar', (tester) async {
      const obrigatorio = PropField(
        key: 'alignment',
        kind: FieldKind.alignment,
        label: 'Alinhamento',
        group: FieldGroups.layout,
        isRequired: true,
      );
      final changes = await _pumpEditor(
        tester,
        value: 'center',
        field: obrigatorio,
      );

      await tester.tap(_cell('Centro'));
      await tester.pump();

      expect(changes, ['center']);
    });
  });

  group('eixos X e Y', () {
    testWidgets('refletem o preset carregado', (tester) async {
      await _pumpEditor(tester, value: 'centerRight');

      expect(_controllerOf(tester, 'X').text, '1');
      expect(_controllerOf(tester, 'Y').text, '0');
    });

    testWidgets('clicar na grade preenche os dois campos', (tester) async {
      await _pumpEditor(tester);

      await tester.tap(_cell('Inferior esquerdo'));
      await tester.pump();

      expect(_controllerOf(tester, 'X').text, '-1');
      expect(_controllerOf(tester, 'Y').text, '1');
    });

    testWidgets('valor livre é emitido como mapa', (tester) async {
      final changes = await _pumpEditor(tester);

      await tester.enterText(
        find.descendant(of: _axisField('X'), matching: find.byType(TextField)),
        '0.3',
      );
      await tester.pump();

      expect(changes.last, {'x': 0.3, 'y': 0.0});
    });

    testWidgets('par que casa um preset é normalizado para o nome', (
      tester,
    ) async {
      final changes = await _pumpEditor(tester);

      await tester.enterText(
        find.descendant(of: _axisField('X'), matching: find.byType(TextField)),
        '-1',
      );
      await tester.pump();
      await tester.enterText(
        find.descendant(of: _axisField('Y'), matching: find.byType(TextField)),
        '-1',
      );
      await tester.pump();

      expect(changes.last, 'topLeft');
    });

    testWidgets('esvaziar os dois campos remove a propriedade', (tester) async {
      final changes = await _pumpEditor(tester, value: 'center');

      final x = find.descendant(
        of: _axisField('X'),
        matching: find.byType(TextField),
      );
      final y = find.descendant(
        of: _axisField('Y'),
        matching: find.byType(TextField),
      );
      await tester.enterText(x, '');
      await tester.pump();
      await tester.enterText(y, '');
      await tester.pump();

      expect(changes.last, isNull);
    });
  });
}
