import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/core/theme/theme.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/cubit/content_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContentErrorView extends StatelessWidget {
  const ContentErrorView({required this.failure, super.key});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(failure),
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              failure.message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: context.read<ContentCubit>().load,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(Failure failure) => switch (failure) {
    NotFoundFailure() => Icons.search_off,
    ValidationFailure() => Icons.rule_folder_outlined,
    NetworkFailure() => Icons.cloud_off_outlined,
    UnexpectedFailure() => Icons.error_outline,
  };
}
