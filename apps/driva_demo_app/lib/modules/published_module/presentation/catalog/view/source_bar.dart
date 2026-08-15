import 'package:driva_demo_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

class SourceBar extends StatelessWidget {
  const SourceBar({
    required this.apiBaseUrl,
    required this.publishableKey,
    super.key,
  });

  final String apiBaseUrl;
  final String publishableKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '$apiBaseUrl · chave ${_shortKey(publishableKey)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _shortKey(String key) =>
      key.length <= 14 ? key : '${key.substring(0, 14)}…';
}
