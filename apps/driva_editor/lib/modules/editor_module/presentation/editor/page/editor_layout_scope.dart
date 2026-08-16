import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:flutter/widgets.dart';

/// O soquete da D7: instalado para que a F7 (tela cheia) alcance o
/// `EditorLayoutController` sem passá-lo por construtor a partir de
/// `EditorWorkspace` — o teto de repasse por construtor já foi atingido
/// (`VR-16-02`).
class EditorLayoutScope extends InheritedNotifier<EditorLayoutController> {
  const EditorLayoutScope({
    required EditorLayoutController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// Acesso sem assinar — para quem só precisa disparar um método do
  /// controller sem se inscrever em rebuilds.
  static EditorLayoutController? of(BuildContext context) {
    return context.getInheritedWidgetOfExactType<EditorLayoutScope>()?.notifier;
  }

  /// Assina — para quem reconstrói quando o `EditorLayout` muda.
  static EditorLayoutController watch(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<EditorLayoutScope>();
    assert(
      scope != null,
      'EditorLayoutScope não encontrado acima deste contexto.',
    );
    return scope!.notifier!;
  }
}
