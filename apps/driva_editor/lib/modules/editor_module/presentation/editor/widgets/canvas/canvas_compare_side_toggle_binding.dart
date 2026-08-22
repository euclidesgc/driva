import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_compare_side.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas_compare_side_toggle.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/history_entry_label.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Busca a versão da candidata no cubit por conta própria, em vez de recebê-la
/// de [CanvasCompareSingleMock] — trocar de candidata não pode forçar o
/// `CanvasPanel` inteiro (mock do rascunho incluso) a reconstruir só para
/// atualizar o número no alternador.
class CanvasCompareSideToggleBinding extends StatelessWidget {
  const CanvasCompareSideToggleBinding({
    required this.side,
    required this.onChanged,
    super.key,
  });

  final CanvasCompareSide side;
  final ValueChanged<CanvasCompareSide> onChanged;

  @override
  Widget build(BuildContext context) {
    final cubit = VersionCompareModeScope.of(context);
    if (cubit == null) {
      return CanvasCompareSideToggle(
        side: side,
        candidateLabel: '',
        onChanged: onChanged,
      );
    }
    return BlocSelector<
      VersionCompareModeCubit,
      VersionCompareModeState,
      String
    >(
      bloc: cubit,
      selector: (state) => switch (state) {
        final VersionCompareModeActive s => historyEntryTitle(s.candidate),
        _ => '',
      },
      builder: (context, candidateLabel) => CanvasCompareSideToggle(
        side: side,
        candidateLabel: candidateLabel,
        onChanged: onChanged,
      ),
    );
  }
}
