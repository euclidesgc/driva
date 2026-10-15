import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/binding.dart';
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

final class _Calls {
  final changes = <Object?>[];
  final binds = <BoundPropValue>[];
  int unbinds = 0;
}

Future<_Calls> _pumpEditor(
  WidgetTester tester, {
  required Object? value,
  PropField field = _texto,
}) async {
  final calls = _Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: PropFieldEditor(
            field: field,
            value: value,
            onChanged: calls.changes.add,
            onBind: calls.binds.add,
            onUnbind: () => calls.unbinds++,
          ),
        ),
      ),
    ),
  );
  return calls;
}

const _ligado = {
  r'$bind': {'source': 'pageParam', 'path': 'nome', 'fallback': 'Visitante'},
};

void main() {
  group('propriedade ligada a variável', () {
    testWidgets('valor com binding troca o editor por tipo pelo chip', (
      tester,
    ) async {
      await _pumpEditor(tester, value: _ligado);

      expect(find.byType(BindingChip), findsOneWidget);
      expect(find.byType(TypedPropEditor), findsNothing);
      expect(find.textContaining('nome'), findsOneWidget);
    });

    testWidgets('valor fixo mantém o editor por tipo', (tester) async {
      await _pumpEditor(tester, value: 'Semana do cliente');

      expect(find.byType(TypedPropEditor), findsOneWidget);
      expect(find.byType(BindingChip), findsNothing);
    });

    testWidgets('o × do chip remove a ligação', (tester) async {
      final calls = await _pumpEditor(tester, value: _ligado);

      await tester.tap(find.byTooltip(BindingChip.removeLabel));
      await tester.pump();

      expect(calls.unbinds, 1);
      expect(calls.changes, isEmpty);
    });

    testWidgets('ligada, não oferece o "voltar ao padrão"', (tester) async {
      await _pumpEditor(tester, value: _ligado);

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

    testWidgets('abre o BindingDialog com o tipo esperado', (tester) async {
      await _pumpEditor(tester, value: null);

      await tester.tap(find.byType(PropBindingButton));
      await tester.pumpAndSettle();

      expect(find.byType(BindingDialog), findsOneWidget);
      expect(find.text('Tipo esperado: texto'), findsOneWidget);
    });

    testWidgets('cancelar não emite mudança', (tester) async {
      final calls = await _pumpEditor(tester, value: 'fixo');

      await tester.tap(find.byType(PropBindingButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(calls.binds, isEmpty);
      expect(calls.changes, isEmpty);
      expect(calls.unbinds, 0);
    });

    testWidgets('tocar o chip reabre o diálogo preenchido', (tester) async {
      await _pumpEditor(tester, value: _ligado);

      await tester.tap(find.byType(BindingChip));
      await tester.pumpAndSettle();

      expect(find.byType(BindingDialog), findsOneWidget);
    });
  });
}
