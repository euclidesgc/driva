import 'package:driva_client/driva_client.dart';
import 'package:driva_demo_app/core/config/app_config.dart';
import 'package:driva_demo_app/injection.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_error_view.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/widgets/content_slug_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sdui_core/sdui_core.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({required this.initialSlug, super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    return ContentPage(initialSlug: getIt<AppConfig>().defaultSlug);
  }

  final String initialSlug;

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  late String _slug = widget.initialSlug;
  int _reloadNonce = 0;

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
        errorBuilder: (context, error) => ContentErrorView(onRetry: _reload),
      ),
      bottomNavigationBar: ContentSlugBar(
        currentSlug: _slug,
        onSubmit: _openSlug,
      ),
    );
  }
}
