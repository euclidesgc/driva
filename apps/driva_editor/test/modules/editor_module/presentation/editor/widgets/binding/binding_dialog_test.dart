import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/binding/binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

const _textoObrigatorio = PropField(
  key: 'data',
  kind: FieldKind.string,
  label: 'Texto',
  group: FieldGroups.content,
  isRequired: true,
);

const _textoOpcional = PropField(
  key: 'tooltip',
  kind: FieldKind.string,
  label: 'Dica',
  group: FieldGroups.content,
);

/// O segundo lugar de uso: a condição de um if/else, fora do inspector.
const _condicao = PropField(
  key: 'condition',
  kind: FieldKind.boolean,
  label: 'Condição',
  group: FieldGroups.content,
  isRequired: true,
);

const _ativo = BindingSource(
  id: 'ativo',
  label: 'Cliente ativo',
  outputType: PropValueType.boolean,
  contexts: {BindingContext.page},
);

const _nome = BindingSource(
  id: 'nome',
  label: 'Nome do cliente',
  outputType: PropValueType.text,
  contexts: {BindingContext.page},
);

const _paginaParam = 'Parâmetro da página';
const _expressaoLivre = 'Expressão livre';

/// O que o `showDialog` devolveu, e se ele já completou.
class _Resultado {
  bool fechou = false;
  BoundPropValue? valor;
}

Future<_Resultado> _abrir(
  WidgetTester tester, {
  required PropField field,
  List<BindingSource> sources = bindingSourceCatalog,
  BoundPropValue? initial,
  Object? initialFallback,
}) async {
  final resultado = _Resultado();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final valor = await showDialog<BoundPropValue>(
                context: context,
                builder: (_) => BindingDialog(
                  field: field,
                  bindingContext: BindingContext.page,
                  sources: sources,
                  initial: initial,
                  initialFallback: initialFallback,
                ),
              );
              resultado
                ..valor = valor
                ..fechou = true;
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return resultado;
}

Finder get _caminho => find.widgetWithText(TextField, 'Nome do parâmetro');

Finder _editorDe(String chave) => find.descendant(
  of: find.byKey(ValueKey(chave)),
  matching: find.byType(TextField),
);

Future<void> _escolher(WidgetTester tester, String fonte) async {
  // Com padrão e prévia abertos o diálogo rola: a fonte pode estar fora da
  // área visível.
  await tester.ensureVisible(find.text(fonte));
  await tester.pumpAndSettle();
  await tester.tap(find.text(fonte));
  await tester.pumpAndSettle();
}

Future<void> _confirmar(WidgetTester tester) async {
  await tester.tap(find.text('Confirmar'));
  await tester.pumpAndSettle();
}

String _texto(WidgetTester tester, Finder finder) =>
    tester.widget<TextField>(finder).controller!.text;

void main() {
  testWidgets('mostra o rótulo da prop e o tipo esperado', (tester) async {
    await _abrir(tester, field: _textoObrigatorio);

    expect(find.text('Ligar "Texto" a uma variável'), findsOneWidget);
    expect(find.text('Tipo esperado: texto'), findsOneWidget);
  });

  group('validação', () {
    testWidgets('prop obrigatória sem valor padrão mostra o erro e não fecha', (
      tester,
    ) async {
      final resultado = await _abrir(tester, field: _textoObrigatorio);

      await _escolher(tester, _paginaParam);
      await tester.enterText(_caminho, 'nomeCliente');
      await _confirmar(tester);

      expect(find.text('Informe um valor padrão'), findsOneWidget);
      expect(find.byType(BindingDialog), findsOneWidget);
      expect(resultado.fechou, isFalse);
    });

    testWidgets('padrão só com espaços conta como ausente', (tester) async {
      final resultado = await _abrir(tester, field: _textoObrigatorio);

      await _escolher(tester, _paginaParam);
      await tester.enterText(_caminho, 'nomeCliente');
      await tester.enterText(_editorDe('binding-fallback'), '   ');
      await _confirmar(tester);

      expect(find.text('Informe um valor padrão'), findsOneWidget);
      expect(resultado.fechou, isFalse);
    });

    testWidgets('nome do parâmetro só com espaços dá erro e não fecha', (
      tester,
    ) async {
      final resultado = await _abrir(tester, field: _textoOpcional);

      await _escolher(tester, _paginaParam);
      await tester.enterText(_caminho, '   ');
      await _confirmar(tester);

      expect(find.text('Informe o nome do parâmetro'), findsOneWidget);
      expect(resultado.fechou, isFalse);
    });

    testWidgets('Confirmar fica desabilitado sem fonte', (tester) async {
      await _abrir(tester, field: _textoOpcional);

      final confirmar = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirmar'),
      );
      expect(confirmar.onPressed, isNull);
    });
  });

  group('resultado', () {
    testWidgets('prop opcional confirma sem padrão, com o caminho aparado', (
      tester,
    ) async {
      final resultado = await _abrir(tester, field: _textoOpcional);

      await _escolher(tester, _paginaParam);
      await tester.enterText(_caminho, '  nomeCliente  ');
      await _confirmar(tester);

      expect(resultado.fechou, isTrue);
      expect(
        resultado.valor,
        const BoundPropValue(
          source: BindingSourceIds.pageParam,
          path: 'nomeCliente',
        ),
      );
    });

    testWidgets('o valor fixo atual vira o padrão inicial', (tester) async {
      final resultado = await _abrir(
        tester,
        field: _textoObrigatorio,
        initialFallback: 'Olá',
      );

      await _escolher(tester, _paginaParam);
      expect(_texto(tester, _editorDe('binding-fallback')), 'Olá');

      await tester.enterText(_caminho, 'saudacao');
      await tester.enterText(_editorDe('binding-preview'), 'Oi, Ana');
      await _confirmar(tester);

      expect(
        resultado.valor,
        const BoundPropValue(
          source: BindingSourceIds.pageParam,
          path: 'saudacao',
          fallback: 'Olá',
          preview: 'Oi, Ana',
        ),
      );
    });

    testWidgets('Cancelar devolve null', (tester) async {
      final resultado = await _abrir(tester, field: _textoOpcional);

      await _escolher(tester, _paginaParam);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(resultado.fechou, isTrue);
      expect(resultado.valor, isNull);
    });

    testWidgets('reabre preenchido e preserva o literal', (tester) async {
      const atual = BoundPropValue(
        source: BindingSourceIds.pageParam,
        path: 'nomeCliente',
        fallback: 'Ana',
        preview: 'Bia',
        literal: 'Olá',
      );
      final resultado = await _abrir(
        tester,
        field: _textoObrigatorio,
        initial: atual,
        initialFallback: 'ignorado',
      );

      expect(_texto(tester, _caminho), 'nomeCliente');
      expect(_texto(tester, _editorDe('binding-fallback')), 'Ana');
      expect(_texto(tester, _editorDe('binding-preview')), 'Bia');

      await _confirmar(tester);

      expect(resultado.valor, atual);
    });
  });

  group('expressão livre', () {
    testWidgets('esconde padrão e prévia e devolve o binding legado', (
      tester,
    ) async {
      final resultado = await _abrir(tester, field: _textoObrigatorio);

      await _escolher(tester, _expressaoLivre);

      expect(find.byKey(const ValueKey('binding-fallback')), findsNothing);
      expect(find.byKey(const ValueKey('binding-preview')), findsNothing);
      expect(find.text('{{'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Expressão'),
        'usuario.nome',
      );
      await _confirmar(tester);

      expect(resultado.valor, const BoundPropValue.legacy('usuario.nome'));
    });

    testWidgets('expressão vazia dá erro e não fecha', (tester) async {
      final resultado = await _abrir(tester, field: _textoOpcional);

      await _escolher(tester, _expressaoLivre);
      await _confirmar(tester);

      expect(find.text('Informe a expressão'), findsOneWidget);
      expect(resultado.fechou, isFalse);
    });

    testWidgets('reabre um {{x}} com a expressão preenchida', (tester) async {
      await _abrir(
        tester,
        field: _textoOpcional,
        initial: const BoundPropValue.legacy('usuario.nome'),
      );

      expect(
        _texto(tester, find.widgetWithText(TextField, 'Expressão')),
        'usuario.nome',
      );
    });
  });

  testWidgets('trocar de fonte mantém nome, padrão e prévia', (tester) async {
    final resultado = await _abrir(
      tester,
      field: _textoObrigatorio,
      sources: [...bindingSourceCatalog, _nome],
    );

    await _escolher(tester, _paginaParam);
    await tester.enterText(_caminho, 'cliente');
    await tester.enterText(_editorDe('binding-fallback'), 'Ana');
    await tester.enterText(_editorDe('binding-preview'), 'Bia');

    // Passa pela expressão livre (que esconde os dois valores) e volta.
    await _escolher(tester, _expressaoLivre);
    expect(
      _texto(tester, find.widgetWithText(TextField, 'Expressão')),
      'cliente',
    );
    await _escolher(tester, 'Nome do cliente');

    expect(_texto(tester, _caminho), 'cliente');
    expect(_texto(tester, _editorDe('binding-fallback')), 'Ana');
    expect(_texto(tester, _editorDe('binding-preview')), 'Bia');

    await _confirmar(tester);

    expect(
      resultado.valor,
      const BoundPropValue(
        source: 'nome',
        path: 'cliente',
        fallback: 'Ana',
        preview: 'Bia',
      ),
    );
  });

  testWidgets('uso isolado: condição booleana com fontes tipadas, sem '
      'inspector nem cubit', (tester) async {
    final resultado = await _abrir(
      tester,
      field: _condicao,
      sources: const [_ativo, _nome],
    );

    expect(find.text('Tipo esperado: booleano'), findsOneWidget);
    final textoTile = tester.widget<BindingSourceTile>(
      find.ancestor(
        of: find.text('Nome do cliente'),
        matching: find.byType(BindingSourceTile),
      ),
    );
    expect(textoTile.isEnabled, isFalse);

    await _escolher(tester, 'Nome do cliente');
    expect(find.byKey(const ValueKey('binding-fallback')), findsNothing);

    await _escolher(tester, 'Cliente ativo');
    await tester.enterText(_caminho, 'ativo');
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('binding-fallback')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();
    await _confirmar(tester);

    expect(
      resultado.valor,
      const BoundPropValue(source: 'ativo', path: 'ativo', fallback: true),
    );
  });
}
