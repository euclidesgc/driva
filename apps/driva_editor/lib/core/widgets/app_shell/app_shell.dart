import 'package:flutter/material.dart';

import 'app_shell_breadcrumb_bar.dart';
import 'app_shell_scope.dart';
import 'app_shell_top_bar.dart';

export 'app_bar_action.dart';
export 'app_shell_slot.dart';
export 'crumb.dart';

/// Casca visual comum a todas as rotas (builder do `ShellRoute`).
///
/// Duas faixas fixas — logo/ações (~56px) e breadcrumb discreto (~30px) — sobre
/// o corpo da página. É um renderizador burro: nunca lê cubit; só desenha os
/// dados que as páginas publicam no [AppShellController] via `AppShellSlot`.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.homeRouteName,
    required this.themeButton,
  });

  final Widget child;
  final String homeRouteName;
  final Widget themeButton;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AppShellController _controller = AppShellController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScope(
      controller: _controller,
      child: Column(
        children: [
          AppShellTopBar(
            homeRouteName: widget.homeRouteName,
            themeButton: widget.themeButton,
          ),
          const AppShellBreadcrumbBar(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
