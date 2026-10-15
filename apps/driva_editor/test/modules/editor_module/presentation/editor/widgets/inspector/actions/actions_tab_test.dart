import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/editing_lock.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/actions/actions.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/prop_field.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

typedef _Patch = Map<String, List<Map<String, dynamic>>?>;

class _Call {
  _Call(this.patch, this.coalesceKey);

  final _Patch patch;
  final String? coalesceKey;
}

class _Host extends StatefulWidget {
  const _Host({
    required this.initial,
    required this.calls,
    this.isReadOnly = false,
    this.width = 360,
  });

  final SduiNode initial;
  final List<_Call> calls;
  final bool isReadOnly;
  final double width;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late SduiNode _node = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: widget.width,
            child: ActionsTab(
              node: _node,
              descriptor: descriptorFor(_node.type),
              isReadOnly: widget.isReadOnly,
              onUpdateEvents: (patch, {coalesceKey}) {
                widget.calls.add(_Call(patch, coalesceKey));
                setState(
                  () => _node = updateNodeEvents(_node, _node.id, patch),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

Future<List<_Call>> _pump(
  WidgetTester tester,
  SduiNode node, {
  bool isReadOnly = false,
  double width = 360,
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final calls = <_Call>[];
  await tester.pumpWidget(
    _Host(initial: node, calls: calls, isReadOnly: isReadOnly, width: width),
  );
  return calls;
}

Future<void> _openTriggerMenu(WidgetTester tester) async {
  await tester.tap(find.text('Adicionar gatilho'));
  await tester.pumpAndSettle();
}

Map<String, dynamic> _snackStep(String message) => {
  'action': 'showSnackBar',
  'params': {'message': message, 'durationMs': 4000},
};

SduiNode _containerWith(Map<String, dynamic> events) =>
    SduiNode(id: 'n1', type: 'container', events: events);

const ValueKey<String> _messageKey = ValueKey('n1_onTap_message');

Object? _lastMessage(List<_Call> calls) =>
    paramsOf(calls.last.patch['onTap']!.first)['message'];

void main() {
  group('ActionsTab: adicionar gatilho', () {
    testWidgets(
      'Ao tocar + Mostrar aviso grava o passo e desenha os parâmetros',
      (tester) async {
        final calls = await _pump(
          tester,
          const SduiNode(id: 'n1', type: 'container'),
        );

        await _openTriggerMenu(tester);
        await tester.tap(find.text('Ao tocar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mostrar aviso'));
        await tester.pumpAndSettle();

        expect(calls.single.patch, {
          'onTap': [_snackStep('')],
        });
        expect(find.byType(PropFieldEditor), findsNWidgets(3));
        expect(find.text('Mensagem'), findsOneWidget);
        expect(find.text('Duração (ms)'), findsOneWidget);
        expect(find.text('Cor de fundo'), findsOneWidget);
        expect(find.byType(StringEditor), findsOneWidget);
        expect(find.byType(NumberEditor), findsOneWidget);
        expect(find.byType(ColorEditor), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(_messageKey),
            matching: find.text(' *'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('fechar o seletor sem escolher não grava', (tester) async {
      final calls = await _pump(
        tester,
        const SduiNode(id: 'n1', type: 'container'),
      );

      await _openTriggerMenu(tester);
      await tester.tap(find.text('Ao tocar'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byType(ActionPickerDialog), findsNothing);
      expect(calls, isEmpty);
    });

    testWidgets('text não oferece Ao mudar', (tester) async {
      await _pump(tester, const SduiNode(id: 't', type: 'text'));

      await _openTriggerMenu(tester);

      expect(find.text('Ao tocar'), findsOneWidget);
      expect(find.text('Ao mudar'), findsNothing);
    });

    testWidgets('switch oferece Ao mudar', (tester) async {
      await _pump(tester, const SduiNode(id: 's', type: 'switch'));

      await _openTriggerMenu(tester);

      expect(find.text('Ao mudar'), findsOneWidget);
    });

    testWidgets('gatilho configurado sai do menu', (tester) async {
      await _pump(
        tester,
        _containerWith({
          'onTap': [_snackStep('Oi')],
        }),
      );

      await _openTriggerMenu(tester);

      expect(
        find.descendant(
          of: find.byType(PopupMenuItem<EventTrigger>),
          matching: find.text('Ao tocar'),
        ),
        findsNothing,
      );
      expect(find.text('Ao tocar duas vezes'), findsWidgets);
    });

    testWidgets('com todos os gatilhos configurados o botão desabilita', (
      tester,
    ) async {
      final descriptor = descriptorFor('container')!;
      await _pump(
        tester,
        _containerWith({
          for (final trigger in descriptor.triggers)
            trigger.name: [
              {'action': 'navigateBack', 'params': <String, dynamic>{}},
            ],
        }),
      );

      expect(
        find.byTooltip('Todos os gatilhos já estão configurados'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PopupMenuButton<EventTrigger>>(
              find.byType(PopupMenuButton<EventTrigger>),
            )
            .enabled,
        isFalse,
      );
      await _openTriggerMenu(tester);
      expect(find.byType(PopupMenuItem<EventTrigger>), findsNothing);
    });
  });

  group('ActionsTab: estado vazio', () {
    testWidgets('tipo sem descritor', (tester) async {
      await _pump(tester, const SduiNode(id: 'x', type: 'tipoInexistente'));

      expect(
        find.text('Este widget não tem gatilhos de ação.'),
        findsOneWidget,
      );
      expect(find.text('Adicionar gatilho'), findsNothing);
    });

    testWidgets('descritor sem gatilhos', (tester) async {
      expect(descriptorFor('column')!.triggers, isEmpty);
      await _pump(tester, const SduiNode(id: 'c', type: 'column'));

      expect(
        find.text('Este widget não tem gatilhos de ação.'),
        findsOneWidget,
      );
      expect(find.text('Adicionar gatilho'), findsNothing);
    });
  });

  group('ActionsTab: parâmetros', () {
    testWidgets('digitar coalesce por parâmetro e não perde o foco', (
      tester,
    ) async {
      final calls = await _pump(
        tester,
        _containerWith({
          'onTap': [_snackStep('')],
        }),
      );
      final field = find.descendant(
        of: find.byKey(_messageKey),
        matching: find.byType(EditableText),
      );

      await tester.tap(field);
      await tester.pump();
      const word = 'Olá';
      for (var i = 1; i <= word.length; i++) {
        tester.testTextInput.enterText(word.substring(0, i));
        await tester.pump();
        expect(
          tester.widget<EditableText>(field).focusNode.hasFocus,
          isTrue,
          reason: 'tecla $i',
        );
      }

      expect(calls, hasLength(word.length));
      expect(
        calls.map((c) => c.coalesceKey),
        everyElement('events:n1:onTap:message'),
      );
      expect(calls.last.patch['onTap']!.first['params'], {
        'message': word,
        'durationMs': 4000,
      });
    });

    testWidgets('ligar guarda o literal e desligar o devolve', (tester) async {
      final calls = await _pump(
        tester,
        _containerWith({
          'onTap': [_snackStep('Olá')],
        }),
      );
      const binding = BoundPropValue(
        source: BindingSourceIds.pageParam,
        path: 'nome',
      );

      tester.widget<PropFieldEditor>(find.byKey(_messageKey)).onBind(binding);
      await tester.pump();

      final bound = _lastMessage(calls);
      expect(calls.last.coalesceKey, isNull);
      expect(literalUnder(bound), 'Olá');
      expect(bound, isNot('Olá'));

      tester.widget<PropFieldEditor>(find.byKey(_messageKey)).onUnbind();
      await tester.pump();

      expect(calls.last.coalesceKey, isNull);
      expect(_lastMessage(calls), 'Olá');
    });

    testWidgets('trocar a ação descarta os parâmetros antigos', (
      tester,
    ) async {
      final calls = await _pump(
        tester,
        _containerWith({
          'onTap': [_snackStep('Oi')],
        }),
      );

      await tester.tap(find.byTooltip('Trocar ação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      expect(calls.single.patch, {
        'onTap': [
          {'action': 'navigateBack', 'params': <String, dynamic>{}},
        ],
      });
      expect(find.byType(PropFieldEditor), findsNothing);
    });

    testWidgets('três passos mostram +2 ações e editar preserva os outros', (
      tester,
    ) async {
      final second = {
        'action': 'wait',
        'params': {'durationMs': 500},
      };
      final third = {'action': 'navigateBack', 'params': <String, dynamic>{}};
      final calls = await _pump(
        tester,
        _containerWith({
          'onTap': [_snackStep('Oi'), second, third],
        }),
      );

      expect(find.text('+2 ações'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byKey(_messageKey),
          matching: find.byType(EditableText),
        ),
        'Tchau',
      );
      await tester.pump();

      expect(calls.last.patch['onTap'], [_snackStep('Tchau'), second, third]);
    });

    testWidgets('ação fora do catálogo mostra o tipo cru, sem parâmetros', (
      tester,
    ) async {
      await _pump(
        tester,
        _containerWith({
          'onTap': [
            {'action': 'acaoNova', 'params': <String, dynamic>{}},
          ],
        }),
      );

      expect(find.text('acaoNova'), findsOneWidget);
      expect(find.byType(PropFieldEditor), findsNothing);
      expect(find.byTooltip('Trocar ação'), findsOneWidget);
    });
  });

  testWidgets('remover grava null no gatilho', (tester) async {
    final calls = await _pump(
      tester,
      _containerWith({
        'onTap': [_snackStep('Oi')],
      }),
    );

    await tester.tap(find.byTooltip('Remover gatilho Ao tocar'));
    await tester.pumpAndSettle();

    expect(calls.single.patch, {'onTap': null});
    expect(find.byType(ConfiguredTriggerCard), findsNothing);
  });

  testWidgets('só leitura tranca os controles', (tester) async {
    final calls = await _pump(
      tester,
      _containerWith({
        'onTap': [_snackStep('Oi')],
      }),
      isReadOnly: true,
    );

    final locks = tester.widgetList<EditingLock>(find.byType(EditingLock));
    expect(locks, hasLength(2));
    expect(locks.every((lock) => lock.locked), isTrue);
    expect(
      find.ancestor(
        of: find.byType(ConfiguredTriggerCard),
        matching: find.byType(EditingLock),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byType(AddTriggerButton),
        matching: find.byType(EditingLock),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Adicionar gatilho'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuItem<EventTrigger>), findsNothing);
    expect(calls, isEmpty);
  });

  testWidgets('cabe na largura mínima do painel', (tester) async {
    await _pump(
      tester,
      _containerWith({
        'onTap': [
          {
            'action': 'copyToClipboard',
            'params': {'text': 'um texto bem comprido para o campo'},
          },
        ],
      }),
      width: AppSizes.workspacePanelMinWidth,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ConfiguredTriggerCard), findsOneWidget);
  });
}
