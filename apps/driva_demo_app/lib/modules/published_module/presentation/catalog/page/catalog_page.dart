import 'dart:async';

import 'package:driva_demo_app/core/config/app_config.dart';
import 'package:driva_demo_app/injection.dart';
import 'package:driva_demo_app/modules/published_module/domain/use_cases/use_cases.dart';
import 'package:driva_demo_app/modules/published_module/presentation/catalog/cubit/catalog_cubit.dart';
import 'package:driva_demo_app/modules/published_module/presentation/catalog/view/catalog_body.dart';
import 'package:driva_demo_app/modules/published_module/presentation/catalog/view/missing_key_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/catalog/view/source_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    if (getIt<AppConfig>().publishableKey.isEmpty) {
      return const MissingKeyView();
    }
    return BlocProvider(
      create: (_) {
        final cubit = CatalogCubit(
          getPublishedContents: getIt<GetPublishedContentsUseCase>(),
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const CatalogPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = getIt<AppConfig>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteúdos publicados'),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: context.read<CatalogCubit>().load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: SourceBar(
            apiBaseUrl: config.apiBaseUrl,
            publishableKey: config.publishableKey,
          ),
        ),
      ),
      body: const CatalogBody(),
    );
  }
}
