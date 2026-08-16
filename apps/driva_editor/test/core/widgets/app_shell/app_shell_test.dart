import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_breadcrumb_bar.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _ImmersiveTogglePage extends StatefulWidget {
  const _ImmersiveTogglePage({super.key});

  @override
  State<_ImmersiveTogglePage> createState() => _ImmersiveTogglePageState();
}

class _ImmersiveTogglePageState extends State<_ImmersiveTogglePage> {
  final Object _token = Object();
  AppShellController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = AppShellScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller?.publish(_token, crumbs: const [], actions: const []);
    });
  }

  void enterImmersive() => _controller?.setImmersive(_token, value: true);

  void exitImmersive() => _controller?.setImmersive(_token, value: false);

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Conteúdo')));
}

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

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Agir'), findsOneWidget);
    expect(find.text('Página Alpha'), findsOneWidget);
  });

  testWidgets('a ação renderizada pelo shell dispara o closure da página '
      '(sem ProviderNotFound)', (tester) async {
    var invoked = 0;
    await tester.pumpWidget(_harness(_router(onAction: () => invoked++)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agir'));
    await tester.pump();

    expect(invoked, 1);
  });

  testWidgets('crumb clicável navega para a rota alvo', (tester) async {
    final router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    router.goNamed('beta');
    await tester.pumpAndSettle();
    expect(find.text('Página Beta'), findsOneWidget);
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
    expect(find.text('Agir'), findsOneWidget);

    router.goNamed('beta');
    await tester.pumpAndSettle();

    expect(find.text('Agir'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets(
    'esconde as duas faixas quando imersivo, mostra normalmente quando não',
    (tester) async {
      final key = GlobalKey<_ImmersiveTogglePageState>();
      final router = GoRouter(
        initialLocation: '/gamma',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(
              homeRouteName: 'gamma',
              themeButton: const SizedBox.shrink(),
              child: child,
            ),
            routes: [
              GoRoute(
                path: '/gamma',
                name: 'gamma',
                builder: (context, state) => _ImmersiveTogglePage(key: key),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      expect(find.byType(AppShellTopBar), findsOneWidget);
      expect(find.byType(AppShellBreadcrumbBar), findsOneWidget);
      expect(find.text('Conteúdo'), findsOneWidget);

      key.currentState!.enterImmersive();
      await tester.pump();

      expect(find.byType(AppShellTopBar), findsNothing);
      expect(find.byType(AppShellBreadcrumbBar), findsNothing);
      expect(find.text('Conteúdo'), findsOneWidget);

      key.currentState!.exitImmersive();
      await tester.pump();

      expect(find.byType(AppShellTopBar), findsOneWidget);
      expect(find.byType(AppShellBreadcrumbBar), findsOneWidget);
      expect(find.text('Conteúdo'), findsOneWidget);
    },
  );
}
