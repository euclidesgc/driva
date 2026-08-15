import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/inspector/wrap_node_menu_item.dart';
import 'package:flutter/material.dart';

/// Comando explícito de envolver (D6, item 38): a mesma `wrapNode` do kernel
/// que o `Ctrl+G` dispara para `column`; aqui o dev escolhe entre Column e Row.
class WrapNodeButton extends StatelessWidget {
  const WrapNodeButton({required this.onWrap, super.key});

  final ValueChanged<String> onWrap;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Envolver em Column ou Row',
      icon: const Icon(Icons.select_all, size: AppIconSizes.s18),
      onSelected: onWrap,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'column',
          child: WrapNodeMenuItem(
            wrapperType: 'column',
            shortcutLabel: 'Ctrl+G',
          ),
        ),
        PopupMenuItem(
          value: 'row',
          child: WrapNodeMenuItem(wrapperType: 'row'),
        ),
      ],
    );
  }
}
