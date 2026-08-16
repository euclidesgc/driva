import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout.dart';
import 'package:flutter/foundation.dart';

/// Fica fora do `EditorCubit` de propósito (D8): o cubit `emit` é o caminho
/// quente do editor, e colapso de painel não tem por que passar por ele.
class EditorLayoutController extends ValueNotifier<EditorLayout> {
  EditorLayoutController([super.initial = const EditorLayout()]);

  void collapseLeftPanel() => _update(leftPanelCollapsed: true);

  void expandLeftPanel() => _update(leftPanelCollapsed: false);

  void collapseRightPanel() => _update(rightPanelCollapsed: true);

  void expandRightPanel() => _update(rightPanelCollapsed: false);

  void setLeftPanelTab(LeftPanelTab tab) => _update(leftPanelTab: tab);

  /// Reabre o painel esquerdo já na aba pedida — a faixa fina é atalho, não só
  /// interruptor (D2, aceite 26): clicar no ícone Árvore com a paleta
  /// colapsada tem de resultar na aba Árvore visível, não na última aba
  /// lembrada.
  void showLeftPanelTab(LeftPanelTab tab) =>
      _update(leftPanelCollapsed: false, leftPanelTab: tab);

  void _update({
    bool? leftPanelCollapsed,
    bool? rightPanelCollapsed,
    LeftPanelTab? leftPanelTab,
  }) {
    value = value.copyWith(
      leftPanelCollapsed: leftPanelCollapsed,
      rightPanelCollapsed: rightPanelCollapsed,
      leftPanelTab: leftPanelTab,
    );
  }
}
