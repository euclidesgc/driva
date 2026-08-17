import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zard/zard.dart';

class EditorLayoutModel extends EditorLayoutSnapshot {
  const EditorLayoutModel({
    super.leftPanelWidth,
    super.rightPanelWidth,
    super.leftPanelCollapsed,
    super.rightPanelCollapsed,
    super.leftPanelTab,
    super.collapsedPaletteGroups,
    super.collapsedInspectorSections,
  });

  // Largura positiva é o único piso exigido aqui: o reclamp contra
  // 200/480 e a janela atual (D13) só a `presentation` consegue fazer, por
  // depender do viewport em memória.
  static final ZMap _schema = z.map({
    'leftPanelWidth': z.double().positive(),
    'rightPanelWidth': z.double().positive(),
    'leftPanelCollapsed': z.bool(),
    'rightPanelCollapsed': z.bool(),
    'leftPanelTab': z.$enum(['widgets', 'tree']),
    'collapsedPaletteGroups': z.list(z.string()),
    'collapsedInspectorSections': z.list(z.string()),
  });

  static Either<Failure, EditorLayoutModel> tryParse(
    Map<String, dynamic> map,
  ) {
    final result = _schema.safeParse(map);
    if (!result.success) {
      return Left(ValidationFailure(z.prettifyError(result.error!)));
    }
    final data = result.data!;
    return Right(
      EditorLayoutModel(
        leftPanelWidth: data['leftPanelWidth'] as double,
        rightPanelWidth: data['rightPanelWidth'] as double,
        leftPanelCollapsed: data['leftPanelCollapsed'] as bool,
        rightPanelCollapsed: data['rightPanelCollapsed'] as bool,
        leftPanelTab: EditorLeftPanelTab.values.byName(
          data['leftPanelTab'] as String,
        ),
        collapsedPaletteGroups: (data['collapsedPaletteGroups'] as List)
            .cast<String>()
            .toSet(),
        collapsedInspectorSections: (data['collapsedInspectorSections'] as List)
            .cast<String>()
            .toSet(),
      ),
    );
  }

  static Map<String, dynamic> toJson(EditorLayoutSnapshot layout) => {
    'leftPanelWidth': layout.leftPanelWidth,
    'rightPanelWidth': layout.rightPanelWidth,
    'leftPanelCollapsed': layout.leftPanelCollapsed,
    'rightPanelCollapsed': layout.rightPanelCollapsed,
    'leftPanelTab': layout.leftPanelTab.name,
    'collapsedPaletteGroups': layout.collapsedPaletteGroups.toList(),
    'collapsedInspectorSections': layout.collapsedInspectorSections.toList(),
  };
}
