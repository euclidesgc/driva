import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:flutter/material.dart';

/// Ação de colapsar um painel lateral do editor em faixa fina (D2), no
/// cabeçalho de `LeftPanel`/`InspectorHeader`. `null` em [onCollapse] = sem
/// `EditorLayoutScope` acima (ex. teste isolado do painel) — o botão some em
/// vez de crashar.
class PanelCollapseButton extends StatelessWidget {
  const PanelCollapseButton({
    required this.icon,
    required this.label,
    required this.onCollapse,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final onCollapse = this.onCollapse;
    if (onCollapse == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: label,
      iconSize: AppIconSizes.s18,
      icon: Icon(icon),
      onPressed: onCollapse,
    );
  }
}
