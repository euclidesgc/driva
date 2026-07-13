import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Monta o [AppShell] via `ShellRoute` real e verifica o mecanismo do slot:
/// as páginas publicam crumbs/ações como DADOS e o shell os renderiza — sem
/// o shell alcançar o estado das páginas.
GoRouter _router({VoidCallback? onAction}) => GoRouter(
  initialLocation: '/alpha',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(
        homeRouteName: 'alpha',
        themeButton: const SizedBox.shrink(),
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/alpha',
          name: 'alpha',
          builder: (context, state) => AppShellSlot(
            crumbs: const [Crumb(label: 'Alpha')],
            actions: [
              AppBarAction.filled(
                label: 'Agir',
                icon: Icons.bolt,
                onPressed: onAction,
              ),
            ],
            child: const Scaffold(body: Center(child: Text('Página Alpha'))),
          ),
        ),
        GoRoute(
          path: '/beta',
          name: 'beta',
          builder: (context, state) => const AppShellSlot(
            crumbs: [
              Crumb(label: 'Alpha', routeName: 'alpha'),
              Crumb(label: 'Beta'),
            ],
            child: Scaffold(body: Center(child: Text('Página Beta'))),
          ),
        ),
      ],
    ),
  ],
);

Widget _harness(GoRouter router) =>
    MaterialApp.router(theme: AppTheme.light, routerConfig: router);

void main() {
  testWidgets('renderiza crumb e ação publicados pela página', (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget); // crumb
    expect(find.text('Agir'), findsOneWidget); // ação no topo
    expect(find.text('Página Alpha'), findsOneWidget); // corpo
  });

  testWidgets(
    'a ação renderizada pelo shell dispara o closure da página '
    '(sem ProviderNotFound)',
    (tester) async {
      var invoked = 0;
      await tester.pumpWidget(_harness(_router(onAction: () => invoked++)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agir'));
      await tester.pump();

      expect(invoked, 1);
    },
  );

  testWidgets('crumb clicável navega para a rota alvo', (tester) async {
    final router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    router.goNamed('beta');
    await tester.pumpAndSettle();
    expect(find.text('Página Beta'), findsOneWidget);
    // Em Beta o crumb "Alpha" é clicável; tocá-lo volta para Alpha.
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(find.text('Página Alpha'), findsOneWidget);
  });

  testWidgets('o topo limpa ao trocar de página sem piscar vazio', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();
    expect(find.text('Agir'), findsOneWidget); // ação de Alpha

    router.goNamed('beta');
    await tester.pumpAndSettle();

    // Beta não publica ações: o slot de Alpha foi liberado, a ação sumiu.
    expect(find.text('Agir'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
  });
}
