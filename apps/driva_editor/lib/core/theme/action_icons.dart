import 'package:flutter/material.dart';

/// Resolve o `iconName` que o `actionCatalog` declara em cada ação, no mesmo
/// contrato do `PropIcons`: `IconData` const não sobrevive a lookup por string
/// em runtime (tree-shaking), então o mapa é explícito.
abstract final class ActionIcons {
  static const _icons = <String, IconData>{
    'actionNavigate': Icons.arrow_forward,
    'actionNavigateBack': Icons.arrow_back,
    'actionLaunchUrl': Icons.open_in_new,
    'actionShowSnackBar': Icons.notifications_outlined,
    'actionCopyToClipboard': Icons.content_copy,
    'actionWait': Icons.hourglass_empty,
    'actionApiCall': Icons.cloud_outlined,
  };

  static IconData? resolve(String? name) => name == null ? null : _icons[name];
}
