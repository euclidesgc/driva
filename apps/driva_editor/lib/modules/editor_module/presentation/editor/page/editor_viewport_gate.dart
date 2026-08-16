import 'package:driva_editor/core/theme/theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/small_viewport_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Única porta de `AppBreakpoints` dentro de `editor_module` (D5›cerca 2a).
/// Abaixo de `compact` ela troca o construtor por [SmallViewportNotice] em
/// vez de deixá-lo se reorganizar — substituição, não adaptação (D23) — para
/// que nenhum widget de `presentation/editor/widgets/` precise conhecer
/// faixa de largura nenhuma.
class EditorViewportGate extends StatelessWidget {
  const EditorViewportGate({
    required this.contentId,
    required this.child,
    super.key,
  });

  final String contentId;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (!AppBreakpoints.isCompact(width)) return child;

    return SmallViewportNotice(
      projectId: context.read<EditorCubit>().projectId,
      contentId: contentId,
    );
  }
}
