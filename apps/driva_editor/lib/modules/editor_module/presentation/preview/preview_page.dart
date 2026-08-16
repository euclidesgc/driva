import 'dart:async';

import 'package:driva_editor/core/config/app_config.dart';
import 'package:driva_editor/core/network/network.dart';
import 'package:driva_editor/injection.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/preview/cubit/preview_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/preview/invalid_preview_screen.dart';
import 'package:driva_editor/modules/editor_module/presentation/preview/widgets/preview_content.dart';
import 'package:driva_editor/modules/editor_module/presentation/preview/widgets/preview_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// A vista de conteúdo sem chrome (D3): rota irmã do `ShellRoute`, para o
/// link que sai do laptop. `showDiagnostics: false` (D17) — não é o editor.
class PreviewPage extends StatelessWidget {
  const PreviewPage({this.imageUrlResolver, super.key});

  /// Só o `pageBuilder` toca o `get_it` para montá-lo (regra do projeto);
  /// aqui ele só é repassado adiante.
  final SduiImageUrlResolver? imageUrlResolver;

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    final projectId = state.pathParameters['projectId'];
    final contentId = state.pathParameters['id'];
    if (projectId == null ||
        projectId.trim().isEmpty ||
        contentId == null ||
        contentId.trim().isEmpty) {
      return const InvalidPreviewScreen();
    }

    // Escrito aqui, antes de montar o cubit, para que a primeira requisição já
    // saia com o `x-project-id` certo — a rota é aberta fria (D18), sem passar
    // por nenhuma tela que carimbe o escopo antes dela.
    getIt<ProjectScope>().projectId = projectId;

    return BlocProvider(
      create: (_) {
        final cubit = PreviewCubit(
          loadContentUseCase: getIt<LoadContentUseCase>(),
          contentId: contentId,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: PreviewPage(
        imageUrlResolver: imageUrlResolverFor(getIt<AppConfig>()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // O `MaterialApp.title` reescreve o `document.title` para "Driva Builder"
    // assim que o app sobe, apagando o que o script do `index.html` deixou. No
    // iOS é esse título que o "Adicionar à tela inicial" sugere, e sem isto os
    // dois alvos instaláveis chegariam ao aparelho com o mesmo nome.
    return Title(
      title: 'Driva Preview',
      color: Theme.of(context).colorScheme.primary,
      child: Scaffold(
        body: BlocBuilder<PreviewCubit, PreviewState>(
          builder: (context, state) => switch (state) {
            PreviewLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            final PreviewFailure s => PreviewErrorView(failure: s.failure),
            final PreviewReady s => PreviewContent(
              spec: s.spec,
              fetchedAt: s.fetchedAt,
              refreshFailure: s.refreshFailure,
              onRefresh: () => context.read<PreviewCubit>().refresh(),
              imageUrlResolver: imageUrlResolver,
            ),
          },
        ),
      ),
    );
  }
}
