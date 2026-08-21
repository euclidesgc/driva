import 'package:flutter/widgets.dart';

/// Deixa um pedaço de UI inerte sem tirá-lo da tela: não recebe toque, não
/// recebe foco por Tab, e o esmaecido conta que está assim de propósito.
///
/// Envolve o **filho**, nunca o rolável inteiro: com o bloqueio aqui, rolar a
/// lista para ler continua funcionando — o que sai de cena é a edição.
class EditingLock extends StatelessWidget {
  const EditingLock({required this.locked, required this.child, super.key});

  /// Público porque a paleta esmaece igual sem poder usar este widget: lá o
  /// item precisa continuar recebendo hover para explicar por tooltip por que
  /// não arrasta, e `IgnorePointer` mataria o tooltip junto com o gesto.
  static const double lockedOpacity = 0.5;

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return ExcludeFocus(
      child: IgnorePointer(
        child: Opacity(opacity: lockedOpacity, child: child),
      ),
    );
  }
}
