import 'package:flutter/widgets.dart';

/// Deixa um pedaço de UI inerte sem tirá-lo da tela: não recebe toque, não
/// recebe foco por Tab, e o esmaecido conta que está assim de propósito.
///
/// Envolve o **filho**, nunca o rolável inteiro: com o bloqueio aqui, rolar a
/// lista para ler continua funcionando — o que sai de cena é a edição.
class EditingLock extends StatelessWidget {
  const EditingLock({required this.locked, required this.child, super.key});

  static const double _lockedOpacity = 0.5;

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return ExcludeFocus(
      child: IgnorePointer(
        child: Opacity(opacity: _lockedOpacity, child: child),
      ),
    );
  }
}
