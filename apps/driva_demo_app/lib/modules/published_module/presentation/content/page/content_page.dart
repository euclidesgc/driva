import 'package:driva_client/driva_client.dart';
import 'package:driva_demo_app/core/config/app_config.dart';
import 'package:driva_demo_app/injection.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_error_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_key_missing_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_not_found_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_slug_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sdui_core/sdui_core.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({
    required this.initialSlug,
    required this.publishableKey,
    super.key,
  });

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    final config = getIt<AppConfig>();
    return ContentPage(
      initialSlug: config.defaultSlug,
      publishableKey: config.publishableKey,
    );
  }

  final String initialSlug;

  /// Formato esperado `pk_...` (D1). Fora desse formato — inclusive o
  /// placeholder versionado em `config/*.json` — não há chave real para
  /// tentar, então a tela nem monta o `DrivaContent` (D-R10.2).
  final String publishableKey;

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  static const _publishableKeyPrefix = 'pk_';

  late String _slug = widget.initialSlug;
  int _reloadNonce = 0;

  bool get _hasWellFormedKey =>
      widget.publishableKey.startsWith(_publishableKeyPrefix);

  void _reload() => setState(() => _reloadNonce++);

  void _openSlug(String slug) {
    setState(() {
      _slug = slug;
      _reloadNonce = 0;
    });
  }

  void _announceAction(SduiAction action) {
    final params = action.params.isEmpty ? '' : ' ${action.params}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Ação recebida: "${action.type}"$params'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasWellFormedKey) {
      return const ContentKeyMissingView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_slug),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: DrivaContent(
        key: ValueKey('$_slug#$_reloadNonce'),
        slug: _slug,
        onAction: _announceAction,
        loadingBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error) => switch (error) {
          DrivaLoadFailure(cause: DrivaLoadCause.notFound) =>
            ContentNotFoundView(onRetry: _reload),
          _ => ContentErrorView(onRetry: _reload),
        },
      ),
      bottomNavigationBar: ContentSlugBar(
        currentSlug: _slug,
        onSubmit: _openSlug,
      ),
    );
  }
}
