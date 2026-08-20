import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_top_bar.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_top_bar_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_fonts.dart';

AppShellController _editorLikeController({
  VoidCallback? onSave,
  VoidCallback? onPublish,
}) {
  final controller = AppShellController()
    ..publish(
      Object(),
      crumbs: const [],
      actions: [
        AppBarAction.icon(
          icon: Icons.undo,
          tooltip: 'Desfazer (Ctrl+Z)',
          onPressed: () {},
        ),
        AppBarAction.icon(
          icon: Icons.redo,
          tooltip: 'Refazer (Ctrl+Shift+Z)',
          onPressed: () {},
        ),
        AppBarAction.filled(
          label: 'Salvar',
          icon: Icons.save_outlined,
          onPressed: onSave,
        ),
        AppBarAction.outlined(label: 'Publish', onPressed: onPublish),
      ],
      status: const AppBarStatus(
        icon: Icons.check_circle,
        label: 'Salvo',
        tone: AppBarStatusTone.success,
      ),
    );
  return controller;
}

Widget _harness(AppShellController controller) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: AppShellScope(
      controller: controller,
      child: const AppShellTopBar(
        homeRouteName: 'home',
        themeButton: SizedBox.shrink(),
      ),
    ),
  ),
);

void main() {
  // Uma chamada só para o arquivo inteiro: `loadAppFonts()` registra as
  // famílias no `FontManifest.json` de novo a cada chamada, e o registro é
  // global ao isolate do teste — chamá-la em cada `testWidgets` (como os
  // seis testes de regressão abaixo precisariam) duplica as famílias a cada
  // rodada e o shaping de texto degrada até o ponto de o `pumpAndSettle`
  // nunca assentar num teste seguinte com texto longo (ex.: a barra em
  // 1600px). `setUpAll` roda uma vez antes de todo o arquivo.
  setUpAll(loadAppFonts);

  testWidgets(
    'em faixa larga (1280px) todas as ações aparecem com ícone e rótulo, '
    'sem botão de overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_harness(_editorLikeController()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Driva Builder'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    },
  );

  for (final width in [700.0, 560.0]) {
    testWidgets(
      'a ${width}px o botão de overflow aparece e o menu abre com as ações '
      'secundárias (Publish) dentro, sem a ação primária (Salvar) sumir',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var saved = 0;
        var published = 0;
        final controller = _editorLikeController(
          onSave: () => saved++,
          onPublish: () => published++,
        );

        await tester.pumpWidget(_harness(controller));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        expect(find.text('Driva Builder'), findsNothing);
        expect(find.text('Driva'), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
        expect(find.text('Salvar'), findsNothing);
        expect(find.text('Publish'), findsNothing);

        final saveButtonFinder = find.byTooltip('Salvar');
        expect(saveButtonFinder, findsOneWidget);
        await tester.tap(saveButtonFinder);
        await tester.pump();
        expect(saved, 1);

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.text('Publish'), findsOneWidget);
        expect(find.text('Desfazer (Ctrl+Z)'), findsOneWidget);
        expect(find.text('Refazer (Ctrl+Shift+Z)'), findsOneWidget);

        await tester.tap(find.text('Publish'));
        await tester.pumpAndSettle();
        expect(published, 1);
      },
    );
  }

  _regressionTests();
}

AppShellController _controllerWithStatus(String label) {
  return AppShellController()..publish(
    Object(),
    crumbs: const [],
    actions: [
      AppBarAction.icon(
        icon: Icons.undo,
        tooltip: 'Desfazer (Ctrl+Z)',
        onPressed: () {},
      ),
      AppBarAction.icon(
        icon: Icons.redo,
        tooltip: 'Refazer (Ctrl+Shift+Z)',
        onPressed: () {},
      ),
      AppBarAction.filled(
        label: 'Salvar',
        icon: Icons.save_outlined,
        onPressed: () {},
      ),
      AppBarAction.filled(
        label: 'Publicar',
        icon: Icons.cloud_upload_outlined,
        onPressed: () {},
      ),
      AppBarAction.icon(
        icon: Icons.cloud_off_outlined,
        tooltip: 'Despublicar',
        onPressed: () {},
      ),
      AppBarAction.outlined(
        label: 'Histórico',
        icon: Icons.history,
        onPressed: () {},
      ),
    ],
    status: AppBarStatus(
      icon: Icons.public,
      label: label,
      tone: AppBarStatusTone.success,
    ),
  );
}

/// Os três rótulos que o editor alterna de verdade, do mais curto ao mais
/// longo — a largura entre eles varia em dezenas de pixels.
const _statusLabels = [
  'No ar (v3)',
  'Nunca publicado',
  'Alterações não publicadas (no ar: v3)',
];

void _regressionTests() {
  testWidgets(
    'a faixa de ações fica na mesma posição quando o texto do status muda',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final positions = <String, Rect>{};
      for (final label in _statusLabels) {
        await tester.pumpWidget(_harness(_controllerWithStatus(label)));
        await tester.pumpAndSettle();
        expect(find.text(label), findsWidgets, reason: 'status $label sumiu');
        positions[label] = tester.getRect(find.byType(AppShellTopBarActions));
      }

      final reference = positions[_statusLabels.first]!;
      for (final label in _statusLabels.skip(1)) {
        expect(
          positions[label],
          reference,
          reason:
              'trocar o status para "$label" moveu a faixa de ações; ela '
              'precisa ficar ancorada à direita, e o status é quem cede '
              'espaço (ver AppShellTopBar)',
        );
      }
    },
  );

  for (final width in [1600.0, 1400.0, 1200.0, 1100.0]) {
    testWidgets(
      'a ${width}px a barra cheia não estoura com o status mais longo',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _harness(_controllerWithStatus(_statusLabels.last)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.more_vert), findsNothing);
        expect(find.text('Histórico'), findsOneWidget);

        final actions = tester.getRect(find.byType(AppShellTopBarActions));
        expect(
          actions.right,
          lessThanOrEqualTo(width),
          reason: 'a faixa de ações vazou para fora da janela',
        );
      },
    );
  }
}
