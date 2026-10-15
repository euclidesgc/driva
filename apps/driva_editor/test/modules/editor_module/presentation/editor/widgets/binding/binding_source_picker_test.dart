import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/binding_source_picker.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/binding_source_tile.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/prop_value_type_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _nome = BindingSource(
  id: 'nome',
  label: 'Nome do cliente',
  outputType: PropValueType.text,
  contexts: {BindingContext.page},
);

const _ativo = BindingSource(
  id: 'ativo',
  label: 'Cliente ativo',
  outputType: PropValueType.boolean,
  contexts: {BindingContext.page},
);

const List<BindingSource> _tipadas = [_nome, _ativo];

Future<List<BindingSource>> _pumpPicker(
  WidgetTester tester, {
  PropValueType expectedType = PropValueType.text,
  BindingContext bindingContext = BindingContext.page,
  List<BindingSource> sources = _tipadas,
  String? selectedSourceId,
}) async {
  final selected = <BindingSource>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: BindingSourcePicker(
            expectedType: expectedType,
            bindingContext: bindingContext,
            selectedSourceId: selectedSourceId,
            onSelected: selected.add,
            sources: sources,
          ),
        ),
      ),
    ),
  );
  return selected;
}

BindingSourceTile _tile(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: find.text(label), matching: find.byType(BindingSourceTile)),
);

void main() {
  group('tipo incompatível', () {
    testWidgets('com tipo texto, a fonte booleana aparece desabilitada e '
        'tocar nela não seleciona', (tester) async {
      final selected = await _pumpPicker(tester);

      expect(find.text('Cliente ativo'), findsOneWidget);
      expect(_tile(tester, 'Cliente ativo').isEnabled, isFalse);
      expect(find.byTooltip(BindingSourceTile.incompatibleHint), findsOne);

      await tester.tap(find.text('Cliente ativo'));
      await tester.pump();

      expect(selected, isEmpty);
    });

    testWidgets('tocar numa fonte compatível chama onSelected com ela', (
      tester,
    ) async {
      final selected = await _pumpPicker(tester);

      expect(_tile(tester, 'Nome do cliente').isEnabled, isTrue);
      await tester.tap(find.text('Nome do cliente'));
      await tester.pump();

      expect(selected, [_nome]);
    });

    testWidgets('a fonte desabilitada expõe enabled: false e a dica', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpPicker(tester);

      expect(
        tester.getSemantics(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.hint == BindingSourceTile.incompatibleHint,
          ),
        ),
        isSemantics(
          label: 'Cliente ativo, booleano',
          hint: 'Tipo incompatível',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('a fonte de saída "qualquer" alimenta qualquer tipo', (
      tester,
    ) async {
      await _pumpPicker(
        tester,
        expectedType: PropValueType.boolean,
        sources: bindingSourceCatalog,
      );

      expect(_tile(tester, 'Expressão livre').isEnabled, isTrue);
      expect(_tile(tester, 'Parâmetro da página').isEnabled, isTrue);
    });
  });

  group('busca e contexto', () {
    testWidgets('a busca filtra pelo rótulo, sem diferenciar maiúsculas', (
      tester,
    ) async {
      await _pumpPicker(tester);

      await tester.enterText(find.byType(TextField), 'NOME');
      await tester.pump();

      expect(find.text('Nome do cliente'), findsOneWidget);
      expect(find.text('Cliente ativo'), findsNothing);
    });

    testWidgets('sem resultado, mostra a mensagem de lista vazia', (
      tester,
    ) async {
      await _pumpPicker(tester);

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump();

      expect(find.byType(BindingSourceTile), findsNothing);
      expect(find.text('Nenhuma fonte encontrada.'), findsOneWidget);
    });

    testWidgets('no contexto de página, o catálogo real não lista o '
        'parâmetro do componente', (tester) async {
      await _pumpPicker(tester, sources: bindingSourceCatalog);

      expect(find.text('Parâmetro da página'), findsOneWidget);
      expect(find.text('Expressão livre'), findsOneWidget);
      expect(find.text('Parâmetro do componente'), findsNothing);
      expect(find.text('Resultado de ação'), findsNothing);
    });

    testWidgets('a fonte selecionada fica marcada', (tester) async {
      await _pumpPicker(tester, selectedSourceId: _nome.id);

      expect(_tile(tester, 'Nome do cliente').isSelected, isTrue);
      expect(_tile(tester, 'Cliente ativo').isSelected, isFalse);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  test('propValueTypeLabel dá um rótulo próprio a cada tipo', () {
    final labels = PropValueType.values.map(propValueTypeLabel).toList();

    expect(labels, everyElement(isNotEmpty));
    expect(labels.toSet(), hasLength(PropValueType.values.length));
    expect(propValueTypeLabel(PropValueType.text), 'texto');
    expect(propValueTypeLabel(PropValueType.any), 'qualquer');
    expect(propValueTypeLabel(PropValueType.declared), 'definido pela fonte');
  });
}
