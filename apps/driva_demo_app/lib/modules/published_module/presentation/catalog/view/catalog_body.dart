import 'package:driva_demo_app/modules/published_module/presentation/catalog/cubit/catalog_cubit.dart';
import 'package:driva_demo_app/modules/published_module/presentation/catalog/view/catalog_empty_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/catalog/view/catalog_error_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/catalog/view/catalog_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CatalogBody extends StatelessWidget {
  const CatalogBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) => switch (state) {
        CatalogLoading() => const Center(child: CircularProgressIndicator()),
        CatalogEmpty() => const CatalogEmptyView(),
        CatalogLoaded(:final items) => CatalogListView(items: items),
        CatalogError(:final failure) => CatalogErrorView(failure: failure),
      },
    );
  }
}
