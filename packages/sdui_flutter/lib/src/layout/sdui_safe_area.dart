import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'package:sdui_flutter/src/parsing/parsers.dart';

/// Área segura implícita de toda página: não é um nó do documento, e sim o
/// chrome que embrulha a raiz. As props vêm de `ContentSpec.safeArea` e a
/// ausência de cada chave cai no default de `safeAreaDescriptor`.
class SduiSafeArea extends StatelessWidget {
  const SduiSafeArea({
    required this.properties,
    required this.child,
    super.key,
  });

  final Map<String, dynamic> properties;
  final Widget child;

  bool _flag(String key) {
    final raw = properties[key];
    if (raw is bool) return raw;
    return safeAreaDescriptor.defaultValueOf(key) as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_flag('enabled')) return child;
    return SafeArea(
      top: _flag('top'),
      bottom: _flag('bottom'),
      left: _flag('left'),
      right: _flag('right'),
      minimum: parseEdgeInsets(properties['minimum']) ?? EdgeInsets.zero,
      maintainBottomViewPadding: _flag('maintainBottomViewPadding'),
      child: child,
    );
  }
}
