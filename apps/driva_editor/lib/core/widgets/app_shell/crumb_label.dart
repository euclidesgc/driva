import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/editor_colors.dart';
import 'crumb.dart';

class CrumbLabel extends StatelessWidget {
  const CrumbLabel({super.key, required this.crumb, required this.isLast});

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
