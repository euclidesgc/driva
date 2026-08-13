import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _largura = PropField(
  key: 'width',
  kind: FieldKind.dimension,
  label: 'Largura',
  group: FieldGroups.size,
  min: 0,
);

/// Segura o valor como o Inspector faz, para o campo receber de volta o que
/// emitiu — sem isso não dá para testar ressincronização nem foco.
class _Harness extends StatefulWidget {
  const _Harness({required this.initial, required this.changes});

  final Object? initial;
  final List<Object?> changes;

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
        child: PropFieldEditor(
          field: _largura,
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
}) async {
  final changes = <Object?>[];
  await tester.pumpWidget(_Harness(initial: value, changes: changes));
  return changes;
}

void main() {
  group('unidade', () {
    testWidgets('em pixels, digitar emite número', (tester) async {
      final changes = await _pumpEditor(tester);

      await tester.enterText(find.byType(TextField), '120');
      await tester.pump();

      expect(changes, [120.0]);
    });

    testWidgets('em porcentagem, digitar emite a string com sufixo', (
      tester,
    ) async {
      final changes = await _pumpEditor(tester);

      await tester.tap(find.byTooltip('Medir em porcentagem do pai'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '70');
      await tester.pump();

      expect(changes.last, '70%');
    });

    testWidgets('valor em porcentagem abre já na unidade certa', (
      tester,
    ) async {
      await _pumpEditor(tester, value: '70%');

      expect(find.text('70'), findsOneWidget);
      expect(find.byTooltip('Preencher o espaço disponível'), findsNothing);
    });

    testWidgets('trocar de unidade limpa o valor', (tester) async {
      final changes = await _pumpEditor(tester, value: 120.0);

      await tester.tap(find.byTooltip('Medir em porcentagem do pai'));
      await tester.pump();

      expect(changes, [null]);
      expect(find.text('120'), findsNothing);
    });

    testWidgets('valor abaixo do mínimo do campo é elevado', (tester) async {
      final changes = await _pumpEditor(tester);

      await tester.enterText(find.byType(TextField), '-40');
      await tester.pump();

      expect(changes.last, 0.0);
    });
  });

  group('preencher o disponível', () {
    testWidgets('o botão emite o token de infinito', (tester) async {
      final changes = await _pumpEditor(tester);

      await tester.tap(find.byTooltip('Preencher o espaço disponível'));
      await tester.pump();

      expect(changes, ['inf']);
      expect(find.text('inf'), findsOneWidget);
    });

    testWidgets('não é oferecido em porcentagem', (tester) async {
      await _pumpEditor(tester);

      expect(find.byTooltip('Preencher o espaço disponível'), findsOneWidget);

      await tester.tap(find.byTooltip('Medir em porcentagem do pai'));
      await tester.pump();

      expect(find.byTooltip('Preencher o espaço disponível'), findsNothing);
    });
  });

  group('binding', () {
    testWidgets('é oferecido em pixels', (tester) async {
      await _pumpEditor(tester);

      expect(find.byTooltip('Definir por variável'), findsOneWidget);
    });

    testWidgets('some em porcentagem, que não aceita expressão', (
      tester,
    ) async {
      await _pumpEditor(tester);

      await tester.tap(find.byTooltip('Medir em porcentagem do pai'));
      await tester.pump();

      expect(find.byTooltip('Definir por variável'), findsNothing);
    });

    testWidgets('valor ligado troca o campo pela faixa de expressão', (
      tester,
    ) async {
      await _pumpEditor(tester, value: '{{produto.largura}}');

      expect(find.text('produto.largura'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('foco', () {
    testWidgets('o cursor não volta ao início ao digitar dígito a dígito', (
      tester,
    ) async {
      await _pumpEditor(tester);

      final campo = find.byType(TextField);
      await tester.tap(campo);
      await tester.pump();

      for (final tecla in ['1', '12', '120']) {
        await tester.enterText(campo, tecla);
        await tester.pump();
      }

      final controller = tester.widget<TextField>(campo).controller!;
      expect(controller.text, '120');
      expect(controller.selection.baseOffset, 3);
    });
  });
}
