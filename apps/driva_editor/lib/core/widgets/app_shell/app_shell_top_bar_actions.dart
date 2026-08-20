import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/widgets/app_shell/app_bar_action.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_action_button.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_actions_overflow_menu.dart';
import 'package:flutter/material.dart';

/// Degradação em três peças da faixa de ações do shell (D35): em faixa
/// larga, cada ação aparece com ícone + rótulo; em faixa estreita, a única
/// ação `filled` da página permanece a um toque como ícone isolado, e todas
/// as demais colapsam no [AppShellActionsOverflowMenu].
class AppShellTopBarActions extends StatelessWidget {
  const AppShellTopBarActions({
    required this.actions,
    required this.compact,
    super.key,
  });

  final List<AppBarAction> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.s8,
        children: [
          for (final action in actions) AppShellActionButton(action: action),
        ],
      );
    }

    AppBarAction? primary;
    final secondary = <AppBarAction>[];
    for (final action in actions) {
      if (primary == null && action.kind == AppBarActionKind.filled) {
        primary = action;
      } else {
        secondary.add(action);
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.s8,
      children: [
        if (secondary.isNotEmpty)
          AppShellActionsOverflowMenu(actions: secondary),
        if (primary != null)
          AppShellActionButton(action: primary, compact: true),
      ],
    );
  }
}

/// Estima a largura que [actions] ocupa na faixa larga, somando o que cada
/// botão de fato compõe: ícone, vão, rótulo medido com a tipografia real e o
/// respiro interno do Material.
///
/// Existe para a barra do topo decidir o colapso **contando o que ela tem**,
/// e não comparando a janela contra uma constante gravada à mão. Essa
/// constante precisou ser recalibrada duas vezes em dois dias — quando
/// `Histórico` ganhou rótulo e quando "salvar e marcar" virou a sétima ação —,
/// e errar a conta estoura o layout ou colapsa cedo demais, sem nada reprovar.
///
/// É estimativa, não medição exata: some [kActionsWidthSafety] antes de
/// comparar. A alternativa exata seria medir a árvore num render object, e
/// isso esbarra em o conteúdo da barra chegar depois do primeiro layout.
double estimatedActionsWidth(
  List<AppBarAction> actions,
  TextStyle? labelStyle,
) {
  var total = 0.0;
  for (final action in actions) {
    total += switch (action.kind) {
      AppBarActionKind.icon => _kIconButtonWidth,
      _ => _labeledButtonWidth(action, labelStyle),
    };
    total += AppSpacing.s8;
  }
  return total;
}

/// Folga sobre [estimatedActionsWidth], para variação de hinting entre
/// ambientes e para o que a estimativa não enxerga (bordas, densidade).
const double kActionsWidthSafety = 24;

const double _kIconButtonWidth = 48;
const double _kLabeledButtonPadding = 40;
const double _kLabeledButtonIconWidth = 26;

double _labeledButtonWidth(AppBarAction action, TextStyle? style) {
  final painter = TextPainter(
    text: TextSpan(text: action.label ?? '', style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final icon = action.icon == null ? 0.0 : _kLabeledButtonIconWidth;
  return painter.width + icon + _kLabeledButtonPadding;
}
