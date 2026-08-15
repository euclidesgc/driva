import 'package:driva_demo_app/core/theme/theme.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/cubit/content_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Procedência do que está na tela: quando o spec foi atualizado e qual o
/// validador de cache que o servidor devolveu.
class ContentMetaBar extends StatelessWidget {
  const ContentMetaBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<ContentCubit, ContentState>(
      builder: (context, state) {
        if (state is! ContentLoaded) return const SizedBox.shrink();
        final content = state.content;
        final etag = content.etag;
        final label =
            'spec de ${_formatted(content.updatedAt)}'
            '${etag == null ? '' : ' · etag $etag'}';
        return Material(
          color: theme.colorScheme.surfaceContainerHighest,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatted(DateTime moment) {
    final local = moment.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
