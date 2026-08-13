import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice.dart';
import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart';

class StatusBarVm extends Equatable {
  const StatusBarVm({required this.diagnostics, required this.notice});

  final List<SpecDiagnostic> diagnostics;
  final EditorNotice? notice;

  @override
  List<Object?> get props => [diagnostics, notice];
}
