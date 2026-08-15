import 'dart:async';

import 'package:driva_demo_app/injection.dart';
import 'package:driva_demo_app/modules/published_module/domain/use_cases/use_cases.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/cubit/content_cubit.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/view/content_body.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/view/content_meta_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ContentPage extends StatelessWidget {
  const ContentPage({required this.slug, super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    final slug = state.pathParameters['slug'] ?? '';
    return BlocProvider(
      create: (_) {
        final cubit = ContentCubit(
          getPublishedContent: getIt<GetPublishedContentUseCase>(),
          slug: slug,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: ContentPage(slug: slug),
    );
  }

  final String slug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(slug),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: context.read<ContentCubit>().load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: const ContentBody(),
      bottomNavigationBar: const ContentMetaBar(),
    );
  }
}
