import 'package:driva_editor/core/theme/action_icons.dart';
import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class ActionPickerTile extends StatelessWidget {
  const ActionPickerTile({
    required this.action,
    required this.onTap,
    this.showCategory = false,
    super.key,
  });

  final ActionDescriptor action;

  final VoidCallback onTap;

  /// Na busca a lista é plana: o breadcrumb diz de que grupo a ação veio.
  final bool showCategory;

  @override
  Widget build(BuildContext context) {
    final breadcrumb = '${action.category} > ${action.label}';
    return Semantics(
      button: true,
      label: showCategory ? breadcrumb : action.label,
      onTap: onTap,
      excludeSemantics: true,
      child: ListTile(
        dense: true,
        leading: Icon(
          ActionIcons.resolve(action.iconName) ?? Icons.bolt_outlined,
          size: AppIconSizes.s18,
        ),
        title: Text(action.label),
        subtitle: showCategory ? Text(breadcrumb) : null,
        onTap: onTap,
      ),
    );
  }
}
