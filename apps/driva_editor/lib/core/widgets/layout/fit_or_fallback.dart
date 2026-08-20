import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Mostra [child] quando ele cabe na largura disponível, e [fallback] quando
/// não cabe — **medindo**, em vez de comparar a largura contra um número.
///
/// O editor calibrava esses limiares à mão: media o cruzamento com a fonte
/// real, somava uma folga e gravava a constante. Funciona até a barra ganhar
/// uma ação — e aí a constante fica errada em silêncio, ou estoura o layout,
/// ou colapsa cedo demais. Aconteceu duas vezes: quando `Histórico` virou
/// botão com rótulo, e quando "salvar e marcar" virou a sétima ação.
///
/// Aqui a decisão sai do próprio conteúdo: mede-se [child] sem restrição de
/// largura e compara-se com o espaço real. Ação nova, fonte diferente,
/// tradução mais longa — tudo entra na conta sozinho.
class FitOrFallback extends MultiChildRenderObjectWidget {
  FitOrFallback({required Widget child, required Widget fallback, super.key})
    : super(children: [child, fallback]);

  @override
  RenderFitOrFallback createRenderObject(BuildContext context) =>
      RenderFitOrFallback();
}

class RenderFitOrFallback extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FitParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FitParentData> {
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _FitParentData) {
      child.parentData = _FitParentData();
    }
  }

  RenderBox get _preferred => firstChild!;
  RenderBox get _fallback => childAfter(firstChild!)!;

  /// Qual dos dois foi escolhido no último layout — o outro não é pintado nem
  /// recebe hit test, para não deixar botões invisíveis clicáveis.
  RenderBox get _chosen => _preferredFits ? _preferred : _fallback;
  bool _preferredFits = true;

  @override
  void performLayout() {
    final available = constraints.maxWidth;
    // Mede sem teto de largura: é isso que dá o quanto o preferido de fato
    // precisa. Exige que ele seja `mainAxisSize.min` — com `max`, medir sem
    // teto responderia "infinito" e nada nunca caberia. No layout real a
    // restrição chega apertada na largura, e aí o `spaceBetween` distribui
    // normalmente: `mainAxisSize` não tem efeito sob restrição apertada.
    //
    // Intrínsecas não servem aqui: as de botões do Material não refletem o
    // tamanho que eles de fato ocupam, e a barra colapsava tarde demais.
    // Layout de verdade, e não dry layout: botões do Material não o
    // implementam e devolveriam tamanho zero, fazendo tudo "caber" e a barra
    // nunca colapsar. É um layout a mais por frame numa barra de poucos
    // botões — barato perto de uma constante que precisa ser recalibrada a
    // cada ação nova.
    _preferred.layout(
      BoxConstraints(maxHeight: constraints.maxHeight),
      parentUsesSize: true,
    );
    _preferredFits = _preferred.size.width <= available;

    final chosen = _chosen..layout(constraints, parentUsesSize: true);
    (chosen.parentData! as _FitParentData).offset = Offset.zero;

    // O não escolhido ainda precisa de layout: sem ele, o framework reclama
    // ao pintar ou medir a árvore em depuração.
    final other = identical(chosen, _preferred) ? _fallback : _preferred
      ..layout(BoxConstraints.tight(chosen.size));
    assert(other.hasSize, 'o filho não escolhido precisa de layout');

    size = constraints.constrain(chosen.size);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.paintChild(_chosen, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintOffset(
      offset: Offset.zero,
      position: position,
      hitTest: (result, transformed) =>
          _chosen.hitTest(result, position: transformed),
    );
  }

  /// Só o escolhido entra na árvore de semântica. O outro continua montado —
  /// é o preço de medir o conteúdo de verdade em vez de chutar uma largura —,
  /// mas um leitor de tela anunciando botões invisíveis seria pior que o
  /// limiar calibrado que este widget substitui.
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitor(_chosen);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _fallback.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _preferred.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _preferred.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _preferred.getMaxIntrinsicHeight(width);
}

class _FitParentData extends ContainerBoxParentData<RenderBox> {}
