import 'package:equatable/equatable.dart';
import 'package:sdui_core/src/model/theme_color_role.dart';
import 'package:sdui_core/src/model/theme_radius_step.dart';
import 'package:sdui_core/src/model/theme_shadow.dart';
import 'package:sdui_core/src/model/theme_shadow_level.dart';
import 'package:sdui_core/src/model/theme_text_style.dart';
import 'package:sdui_core/src/model/theme_text_style_name.dart';

/// A cor fica como texto hex porque o kernel é Dart puro: quem a converte em
/// `Color` é o renderer.
class ProjectTheme extends Equatable {
  const ProjectTheme({
    required this.colors,
    required this.textStyles,
    required this.radii,
    required this.shadows,
  });

  final Map<ThemeColorRole, String> colors;
  final Map<ThemeTextStyleName, ThemeTextStyle> textStyles;
  final Map<ThemeRadiusStep, double> radii;
  final Map<ThemeShadowLevel, ThemeShadow> shadows;

  Map<String, dynamic> toJson() => {
    'colors': {
      for (final role in ThemeColorRole.values) role.name: ?colors[role],
    },
    'textStyles': {
      for (final name in ThemeTextStyleName.values)
        name.name: ?textStyles[name]?.toJson(),
    },
    'radii': {
      for (final step in ThemeRadiusStep.values) step.name: ?radii[step],
    },
    'shadows': {
      for (final level in ThemeShadowLevel.values)
        level.name: ?shadows[level]?.toJson(),
    },
  };

  @override
  List<Object?> get props => [colors, textStyles, radii, shadows];
}
