import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Entrega ao canvas só `isActive` — se o modo de comparação está ligado —
/// nunca o estado inteiro.
///
/// [VersionCompareModeCubit] reemite a cada tecla digitada no rascunho, para
/// manter o `baseSpec`/diff em dia, e a cada troca de candidata; um
/// `BlocBuilder` aqui arrastaria o mock do rascunho para dentro desses dois
/// ciclos, forçando `PreviewSurface` a rebuildar mesmo com o throttle dele.
/// O `BlocSelector` projeta só `isActive` — que muda ao entrar/sair do modo,
/// não a cada tecla nem a cada candidata — e quem depende do spec ou da
/// versão da candidata assina o cubit por conta própria, longe deste
/// subtree, em `CanvasComparePane` e `CanvasCompareSideToggleBinding`.
class CanvasCompareChromeBinding extends StatelessWidget {
  const CanvasCompareChromeBinding({required this.builder, super.key});

  final Widget Function(
    BuildContext context, {
    required bool isActive,
    required VersionCompareModeCubit? compareCubit,
  })
  builder;

  @override
  Widget build(BuildContext context) {
    final cubit = VersionCompareModeScope.of(context);
    if (cubit == null) {
      return builder(context, isActive: false, compareCubit: null);
    }
    return BlocSelector<VersionCompareModeCubit, VersionCompareModeState, bool>(
      bloc: cubit,
      selector: (state) => state is VersionCompareModeActive,
      builder: (context, isActive) =>
          builder(context, isActive: isActive, compareCubit: cubit),
    );
  }
}
