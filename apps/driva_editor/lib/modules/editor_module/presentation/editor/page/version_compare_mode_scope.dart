import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:flutter/widgets.dart';

/// O soquete do modo de comparação, no mesmo padrão do `EditorLayoutScope`
/// (D7): o canvas alcança o cubit sem recebê-lo por construtor através de
/// `EditorWorkspace` e `CenterArea`.
///
/// [of] devolve `null` de propósito quando o soquete não está instalado — o
/// modo de comparação é **opcional**, e o canvas precisa continuar montável
/// sem ele (é o que os testes de canvas e de layout fazem). Um provider
/// obrigatório acoplaria o canvas a uma feature que ele não precisa conhecer.
class VersionCompareModeScope extends InheritedWidget {
  const VersionCompareModeScope({
    required this.cubit,
    required super.child,
    super.key,
  });

  final VersionCompareModeCubit cubit;

  static VersionCompareModeCubit? of(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<VersionCompareModeScope>()
        ?.cubit;
  }

  @override
  bool updateShouldNotify(VersionCompareModeScope oldWidget) =>
      oldWidget.cubit != cubit;
}
