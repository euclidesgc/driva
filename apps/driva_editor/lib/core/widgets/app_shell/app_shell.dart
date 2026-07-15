import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/editor_colors.dart';
import '../branding/branding.dart';
import 'app_bar_action.dart';
import 'app_shell_scope.dart';
import 'crumb.dart';

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
          _TopBar(
            homeRouteName: widget.homeRouteName,
            themeButton: widget.themeButton,
          ),
          const _BreadcrumbBar(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.homeRouteName, required this.themeButton});

  final String homeRouteName;
  final Widget themeButton;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final controller = AppShellScope.watch(context);
    return Material(
      color: colors.panel,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            AppWordmark(onTap: () => context.goNamed(homeRouteName)),
            const Spacer(),
            for (final action in controller.actions) ...[
              _ActionButton(action: action),
              const SizedBox(width: 8),
            ],
            if (controller.status case final status?) ...[
              _StatusIndicator(status: status),
              const SizedBox(width: 12),
            ],
            themeButton,
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final AppBarAction action;

  @override
  Widget build(BuildContext context) {
    final icon = action.icon;
    final label = action.label ?? '';
    final Widget button = switch (action.kind) {
      AppBarActionKind.filled =>
        icon != null
            ? FilledButton.icon(
                onPressed: action.onPressed,
                icon: Icon(icon, size: 18),
                label: Text(label),
              )
            : FilledButton(onPressed: action.onPressed, child: Text(label)),
      AppBarActionKind.outlined =>
        icon != null
            ? OutlinedButton.icon(
                onPressed: action.onPressed,
                icon: Icon(icon, size: 18),
                label: Text(label),
              )
            : OutlinedButton(onPressed: action.onPressed, child: Text(label)),
      AppBarActionKind.text =>
        icon != null
            ? TextButton.icon(
                onPressed: action.onPressed,
                icon: Icon(icon, size: 18),
                label: Text(label),
              )
            : TextButton(onPressed: action.onPressed, child: Text(label)),
      AppBarActionKind.icon => IconButton(
        onPressed: action.onPressed,
        icon: Icon(icon),
      ),
    };
    final tooltip = action.tooltip;
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final AppBarStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status.tone) {
      AppBarStatusTone.success => Theme.of(
        context,
      ).extension<EditorColors>()!.success,
      AppBarStatusTone.neutral => scheme.onSurfaceVariant,
      AppBarStatusTone.danger => scheme.error,
    };
    return Semantics(
      liveRegion: true,
      label: 'Status: ${status.label}',
      child: Row(
        children: [
          Icon(status.icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(status.label, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final controller = AppShellScope.watch(context);
    final crumbs = controller.crumbs;
    return Material(
      color: colors.panelAlt,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        alignment: Alignment.centerLeft,
        child: crumbs.isEmpty
            ? const SizedBox.shrink()
            : Row(
                children: [
                  for (var i = 0; i < crumbs.length; i++) ...[
                    if (i > 0)
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colors.inkMuted,
                      ),
                    _CrumbLabel(
                      crumb: crumbs[i],
                      isLast: i == crumbs.length - 1,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CrumbLabel extends StatelessWidget {
  const _CrumbLabel({required this.crumb, required this.isLast});

  final Crumb crumb;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final routeName = crumb.routeName;
    final style = Theme.of(context).textTheme.bodySmall;

    if (isLast || routeName == null) {
      return Text(
        crumb.label,
        style: style?.copyWith(
          color: colors.inkPrimary,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return InkWell(
      onTap: () =>
          context.goNamed(routeName, pathParameters: crumb.pathParameters),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          crumb.label,
          style: style?.copyWith(color: colors.inkSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
