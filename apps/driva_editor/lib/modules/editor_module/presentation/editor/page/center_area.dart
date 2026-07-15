import 'package:flutter/material.dart';

import '../../../../../core/theme/editor_colors.dart';
import '../widgets/json_preview_panel.dart';
import 'canvas_area.dart';
import 'center_tab_label.dart';

/// Área central com abas ao estilo VS Code: alterna entre o **Mock** (canvas)
/// e o **JSON** do spec ao vivo. Só a casca (a `TabBar`) vive aqui; cada aba
/// assina sua própria fatia do cubit, então trocar de aba não reconstrói a
/// outra desnecessariamente.
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
                ColoredBox(color: colors.canvasBackdrop, child: CanvasArea()),
                const JsonPreviewPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
