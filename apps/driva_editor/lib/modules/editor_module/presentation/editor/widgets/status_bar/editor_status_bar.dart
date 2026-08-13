import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_notice.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/status_bar/diagnostic_row.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/status_bar/editor_notice_message.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/status_bar/status_bar_summary.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// Rodapé fixo do editor: conta os problemas do documento e, aberto, lista
/// cada um com atalho para selecionar o nó. É o contraponto de deixar o
/// usuário soltar o widget onde quiser — nada é bloqueado, tudo é relatado.
class EditorStatusBar extends StatefulWidget {
  const EditorStatusBar({
    required this.diagnostics,
    required this.notice,
    required this.onSelectNode,
    super.key,
  });

  final List<SpecDiagnostic> diagnostics;
  final EditorNotice? notice;
  final ValueChanged<String> onSelectNode;

  @override
  State<EditorStatusBar> createState() => _EditorStatusBarState();
}

class _EditorStatusBarState extends State<EditorStatusBar> {
  static const double _listMaxHeight = 168;

  bool _isExpanded = false;

  @override
  void didUpdateWidget(EditorStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.diagnostics.isEmpty && _isExpanded) _isExpanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final diagnostics = widget.diagnostics;
    final errors = diagnostics
        .where((d) => d.severity == DiagnosticSeverity.error)
        .length;
    final notice = widget.notice;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isExpanded && diagnostics.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _listMaxHeight),
              child: ColoredBox(
                color: colors.panelAlt,
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.s4,
                  ),
                  itemCount: diagnostics.length,
                  itemBuilder: (context, index) => DiagnosticRow(
                    diagnostic: diagnostics[index],
                    onSelect: () =>
                        widget.onSelectNode(diagnostics[index].nodeId),
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 28,
            child: Row(
              children: [
                StatusBarSummary(
                  errorCount: errors,
                  warningCount: diagnostics.length - errors,
                  isExpanded: _isExpanded,
                  onToggle: diagnostics.isEmpty
                      ? null
                      : () => setState(() => _isExpanded = !_isExpanded),
                ),
                if (notice != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.s12),
                      child: Text(
                        EditorNoticeMessage.of(notice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTypography.sm,
                          color: colors.inkMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
