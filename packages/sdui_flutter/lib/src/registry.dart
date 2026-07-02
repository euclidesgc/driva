import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'renderer.dart';

/// Constrói um widget a partir de um nó. Recebe o renderer para descer na
/// árvore (filhos).
typedef SduiBuilder = Widget Function(
  BuildContext context,
  SduiNode node,
  SduiRenderer renderer,
);

/// Mapa imutável `type → builder`. Adicionar um primitivo = uma entrada aqui
/// (+ descriptor no catálogo do `sdui_core`).
class SduiRegistry {
  SduiRegistry(Map<String, SduiBuilder> builders)
      : _builders = Map.unmodifiable(builders);

  final Map<String, SduiBuilder> _builders;

  SduiBuilder? operator [](String type) => _builders[type];
  bool contains(String type) => _builders.containsKey(type);
  Iterable<String> get types => _builders.keys;
}
