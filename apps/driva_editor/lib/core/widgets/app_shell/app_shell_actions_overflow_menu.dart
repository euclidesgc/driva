import 'package:driva_editor/core/widgets/app_shell/app_bar_action.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_overflow_menu_item.dart';
import 'package:flutter/material.dart';

/// Faixa 1 do shell em faixa estreita (D35): as ações secundárias — todas
/// menos a `filled` primária, que a `AppShellTopBarActions` mantém fora como
/// ícone isolado — colapsam aqui em vez de estourar a `Row` do topo. Nenhuma
/// ação declarada some: ou está visível, ou está dentro deste menu.
class AppShellActionsOverflowMenu extends StatelessWidget {
  const AppShellActionsOverflowMenu({required this.actions, super.key});

  final List<AppBarAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Mais ações',
      child: PopupMenuButton<AppBarAction>(
        tooltip: 'Mais ações',
        icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
        color: theme.colorScheme.surface,
        onSelected: (action) => action.onPressed?.call(),
        itemBuilder: (context) => [
          for (final action in actions)
            PopupMenuItem<AppBarAction>(
              value: action,
              enabled: action.onPressed != null,
              child: AppShellOverflowMenuItem(action: action),
            ),
        ],
      ),
    );
  }
}
