import 'package:driva_demo_app/core/theme/theme.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:driva_demo_app/modules/published_module/presentation/catalog/cubit/catalog_cubit.dart';
import 'package:driva_demo_app/modules/published_module/presentation/catalog/view/catalog_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CatalogListView extends StatelessWidget {
  const CatalogListView({required this.items, super.key});

  final List<PublishedSummary> items;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<CatalogCubit>().load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => CatalogTile(item: items[index]),
      ),
    );
  }
}
