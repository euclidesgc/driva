import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/view/empty_root_view.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

/// O ponto do app inteiro: o spec que veio da API vira árvore de widgets pelo
/// mesmo renderer que o editor usa no preview.
class RenderedContentView extends StatelessWidget {
  const RenderedContentView({required this.content, super.key});

  final PublishedContent content;

  @override
  Widget build(BuildContext context) {
    if (content.spec.root == null) {
      return EmptyRootView(name: content.spec.name);
    }
    return SduiView.content(
      content.spec,
      onAction: (action) => _announce(context, action),
    );
  }

  /// Executar ação é do runtime do SDK (roadmap 33) — aqui o app só mostra
  /// que a ação **chegou** como dado, provando o contrato do spec.
  void _announce(BuildContext context, SduiAction action) {
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
}
