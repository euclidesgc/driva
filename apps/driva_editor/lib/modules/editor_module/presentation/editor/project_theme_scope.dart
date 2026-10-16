import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:sdui_core/sdui_core.dart';

/// Entrega o tema do projeto aberto aos pontos que montam `SduiView.content`.
class ProjectThemeScope extends InheritedWidget {
  const ProjectThemeScope({
    required this.theme,
    required super.child,
    super.key,
  });

  final ProjectTheme theme;

  /// Sem escopo, cai no tema padrão do kernel.
  static ProjectTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProjectThemeScope>()?.theme ??
      kDefaultProjectTheme;

  @override
  bool updateShouldNotify(ProjectThemeScope oldWidget) =>
      theme != oldWidget.theme;
}

/// Resolve o `projectFuture` e o expõe no [ProjectThemeScope]; enquanto não
/// resolve, ou se falhar, vale o tema padrão (o child nunca é bloqueado).
class ProjectThemeHost extends StatelessWidget {
  const ProjectThemeHost({
    required this.projectFuture,
    required this.child,
    super.key,
  });

  final Future<Either<Failure, Project>> projectFuture;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, Project>>(
      future: projectFuture,
      builder: (context, snapshot) {
        final theme =
            snapshot.data?.fold((_) => null, (p) => p.theme) ??
            kDefaultProjectTheme;
        return ProjectThemeScope(theme: theme, child: child);
      },
    );
  }
}
