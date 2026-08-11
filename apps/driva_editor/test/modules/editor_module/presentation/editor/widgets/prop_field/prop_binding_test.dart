import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _texto = PropField(
  key: 'data',
  kind: FieldKind.string,
  label: 'Texto',
  group: FieldGroups.content,
);

Future<List<Object?>> _pumpEditor(
  WidgetTester tester, {
  PropField field = _texto,
  required Object? value,
}) async {
  final changes = <Object?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: PropFieldEditor(
            field: field,
            value: value,
            onChanged: changes.add,
          ),
        ),
      ),
    ),
  );
  return changes;
}

void main() {
  group('propriedade ligada a variável', () {
    testWidgets('valor com binding troca o editor por tipo pela faixa', (
      tester,
    ) async {
      await _pumpEditor(tester, value: '{{usuario.nome}}');

      expect(find.byType(PropBindingEditor), findsOneWidget);
      expect(find.byType(TypedPropEditor), findsNothing);
      expect(find.text('usuario.nome'), findsOneWidget);
    });

    testWidgets('valor fixo mantém o editor por tipo', (tester) async {
      await _pumpEditor(tester, value: 'Semana do cliente');

      expect(find.byType(TypedPropEditor), findsOneWidget);
      expect(find.byType(PropBindingEditor), findsNothing);
    });

    testWidgets('"voltar a valor fixo" remove a chave', (tester) async {
      final changes = await _pumpEditor(tester, value: '{{usuario.nome}}');

      await tester.tap(find.byTooltip('Voltar a valor fixo'));
      await tester.pump();

      expect(changes, [null]);
    });

    testWidgets('ligada, não oferece o "voltar ao padrão"', (tester) async {
      await _pumpEditor(tester, value: '{{usuario.nome}}');

      expect(find.byType(PropResetButton), findsNothing);
    });
  });

  group('botão de binding', () {
    testWidgets('aparece em campo bindável e some quando não é', (
      tester,
    ) async {
      await _pumpEditor(tester, value: 'x');
      expect(find.byType(PropBindingButton), findsOneWidget);

      const naoBindavel = PropField(
        key: 'data',
        kind: FieldKind.string,
        label: 'Texto',
        group: FieldGroups.content,
        isBindable: false,
      );
      await _pumpEditor(tester, field: naoBindavel, value: 'x');
      expect(find.byType(PropBindingButton), findsNothing);
    });

    testWidgets('abre o diálogo com o tipo esperado da propriedade', (
      tester,
    ) async {
      await _pumpEditor(tester, value: null);

      await tester.tap(find.byType(PropBindingButton));
      await tester.pumpAndSettle();

      expect(find.byType(PropBindingDialog), findsOneWidget);
      expect(find.text('Tipo esperado: texto'), findsOneWidget);
    });
  });

  group('diálogo de binding', () {
    testWidgets('aplicar grava a expressão entre chaves', (tester) async {
      final changes = await _pumpEditor(tester, value: null);

      await tester.tap(find.byType(PropBindingButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'usuario.nome');
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(changes, ['{{usuario.nome}}']);
    });

    testWidgets('aplicar vazio remove a chave em vez de gravar "{{}}"', (
      tester,
    ) async {
      final changes = await _pumpEditor(tester, value: null);

      await tester.tap(find.byType(PropBindingButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(changes, [null]);
    });

    testWidgets('cancelar não emite mudança', (tester) async {
      final changes = await _pumpEditor(tester, value: 'fixo');

      await tester.tap(find.byType(PropBindingButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
    });

    testWidgets('reabrir com binding traz a expressão preenchida', (
      tester,
    ) async {
      await _pumpEditor(tester, value: '{{produto.preco}}');

      await tester.tap(find.byType(PropBindingButton));
      await tester.pumpAndSettle();

      expect(find.text('produto.preco'), findsWidgets);
      expect(find.text('Voltar a valor fixo'), findsOneWidget);
    });
  });
}
