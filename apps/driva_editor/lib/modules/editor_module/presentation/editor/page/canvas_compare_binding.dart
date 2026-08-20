import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Entrega ao canvas o estado do modo de comparação **quando ele existe**.
///
/// Sem o soquete instalado, chama [builder] uma vez com o estado inativo e
/// cubit nulo: o canvas segue montável sem a feature, que é o que permite
/// testar canvas e layout sem arrastar o modo junto. Com o soquete, assina o
/// cubit por `bloc:` explícito — não por provider — porque o soquete já é o
/// canal e um `BlocProvider` obrigatório desfaria a opcionalidade.
class CanvasCompareBinding extends StatelessWidget {
  const CanvasCompareBinding({required this.builder, super.key});

  final Widget Function(
    BuildContext context,
    VersionCompareModeState state,
    VersionCompareModeCubit? cubit,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final cubit = VersionCompareModeScope.of(context);
    if (cubit == null) {
      return builder(context, const VersionCompareModeInactive(), null);
    }
    return BlocBuilder<VersionCompareModeCubit, VersionCompareModeState>(
      bloc: cubit,
      builder: (context, state) => builder(context, state, cubit),
    );
  }
}
