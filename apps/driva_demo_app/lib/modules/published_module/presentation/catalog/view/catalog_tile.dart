import 'package:driva_demo_app/core/theme/theme.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:driva_demo_app/modules/published_module/published_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CatalogTile extends StatelessWidget {
  const CatalogTile({required this.item, super.key});

  final PublishedSummary item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      child: ListTile(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        leading: const Icon(Icons.article_outlined),
        title: Text(item.name),
        subtitle: Text(
          item.slug,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed(
          PublishedRoutes.contentName,
          pathParameters: {'slug': item.slug},
        ),
      ),
    );
  }
}
