import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
