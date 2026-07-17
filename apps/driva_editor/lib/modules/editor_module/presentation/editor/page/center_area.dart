import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/canvas_area.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/center_tab_label.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/json_preview_panel.dart';
import 'package:flutter/material.dart';

class CenterArea extends StatelessWidget {
  const CenterArea({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.panel,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  height: 40,
                  child: CenterTabLabel(icon: Icons.smartphone, label: 'Mock'),
                ),
                Tab(
                  height: 40,
                  child: CenterTabLabel(icon: Icons.data_object, label: 'JSON'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ColoredBox(
                  color: colors.canvasBackdrop,
                  child: const CanvasArea(),
                ),
                const JsonPreviewPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
