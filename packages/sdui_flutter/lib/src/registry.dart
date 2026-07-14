import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';

import 'renderer.dart';

/// Constrói um widget a partir de um nó. Recebe o renderer para descer na
/// árvore (filhos).
///
/// **Exceção documentada do Gate 1** (zero função/método que retorna `Widget`):
/// os builders do renderer SDUI são um padrão de registry/plugin — cada tipo do
/// catálogo mapeia para um builder `node → Widget`. Ficam fora do gate por
/// design; o isolamento de rebuild que o gate visa vem do wrapper por-nó do
/// `renderer.dart` (`_SduiNodeView`, chaveado pelo `id`), não de transformar
/// cada builder num widget.
typedef SduiBuilder =
    Widget Function(BuildContext context, SduiNode node, SduiRenderer renderer);

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
