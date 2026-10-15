import 'dart:async';

import 'package:driva_client/driva_client.dart';
import 'package:driva_demo_app/core/config/app_config.dart';
import 'package:driva_demo_app/core/platform/url_opener.dart';
import 'package:driva_demo_app/injection.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/actions/content_action_runner.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_error_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_key_missing_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_not_found_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_slug_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({
    required this.initialSlug,
    required this.publishableKey,
    this.urlOpener = openUrlExternally,
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

  final UrlOpener urlOpener;

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  static const _publishableKeyPrefix = 'pk_';

  late String _slug = widget.initialSlug;
  int _reloadNonce = 0;
  final List<String> _history = [];

  bool get _hasWellFormedKey =>
      widget.publishableKey.startsWith(_publishableKeyPrefix);

  void _reload() => setState(() => _reloadNonce++);

  ContentActionRunner get _runner => ContentActionRunner(
    onNavigate: _navigate,
    onNavigateBack: _navigateBack,
    showMessage: _showMessage,
    urlOpener: widget.urlOpener,
  );

  void _openSlug(String slug) {
    setState(() {
      _history.clear();
      _slug = slug;
      _reloadNonce = 0;
    });
  }

  void _navigate(String slug) {
    setState(() {
      _history.add(_slug);
      _slug = slug;
      _reloadNonce = 0;
    });
  }

  void _navigateBack() {
    if (_history.isEmpty) {
      Navigator.maybePop(context);
      return;
    }
    setState(() {
      _slug = _history.removeLast();
      _reloadNonce = 0;
    });
  }

  void _showMessage(String text, {Duration? duration, Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: duration ?? ContentActionRunner.defaultSnackBarDuration,
          backgroundColor: backgroundColor,
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
        onAction: (action) => unawaited(_runner.run(action)),
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
