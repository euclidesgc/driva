import 'package:sdui_core/src/model/project_theme.dart';
import 'package:sdui_core/src/model/theme_color_role.dart';
import 'package:sdui_core/src/model/theme_radius_step.dart';
import 'package:sdui_core/src/model/theme_shadow.dart';
import 'package:sdui_core/src/model/theme_shadow_level.dart';
import 'package:sdui_core/src/model/theme_text_style.dart';
import 'package:sdui_core/src/model/theme_text_style_name.dart';

/// Baseline do Material 3 claro, para um spec com `$theme` desenhar como o
/// app desenhava antes de existir tema. `success`, `warning` e `info` não
/// existem no M3 e vêm da paleta do Material 2.
const ProjectTheme kDefaultProjectTheme = ProjectTheme(
  colors: {
    ThemeColorRole.primary: '#6750A4',
    ThemeColorRole.secondary: '#625B71',
    ThemeColorRole.tertiary: '#7D5260',
    ThemeColorRole.alternate: '#CAC4D0',
    ThemeColorRole.primaryText: '#1D1B20',
    ThemeColorRole.secondaryText: '#49454F',
    ThemeColorRole.primaryBackground: '#FEF7FF',
    ThemeColorRole.secondaryBackground: '#F7F2FA',
    ThemeColorRole.accent1: '#EADDFF',
    ThemeColorRole.accent2: '#E8DEF8',
    ThemeColorRole.accent3: '#FFD8E4',
    ThemeColorRole.accent4: '#E6E0E9',
    ThemeColorRole.success: '#2E7D32',
    ThemeColorRole.warning: '#EF6C00',
    ThemeColorRole.error: '#B3261E',
    ThemeColorRole.info: '#1976D2',
  },
  textStyles: {
    ThemeTextStyleName.displayLarge: ThemeTextStyle(
      fontSize: 57,
      fontWeight: 'w400',
      lineHeight: 1.12,
      letterSpacing: -0.25,
    ),
    ThemeTextStyleName.displayMedium: ThemeTextStyle(
      fontSize: 45,
      fontWeight: 'w400',
      lineHeight: 1.16,
      letterSpacing: 0,
    ),
    ThemeTextStyleName.displaySmall: ThemeTextStyle(
      fontSize: 36,
      fontWeight: 'w400',
      lineHeight: 1.22,
      letterSpacing: 0,
    ),
    ThemeTextStyleName.headlineLarge: ThemeTextStyle(
      fontSize: 32,
      fontWeight: 'w400',
      lineHeight: 1.25,
      letterSpacing: 0,
    ),
    ThemeTextStyleName.headlineMedium: ThemeTextStyle(
      fontSize: 28,
      fontWeight: 'w400',
      lineHeight: 1.29,
      letterSpacing: 0,
    ),
    ThemeTextStyleName.headlineSmall: ThemeTextStyle(
      fontSize: 24,
      fontWeight: 'w400',
      lineHeight: 1.33,
      letterSpacing: 0,
    ),
    ThemeTextStyleName.titleLarge: ThemeTextStyle(
      fontSize: 22,
      fontWeight: 'w400',
      lineHeight: 1.27,
      letterSpacing: 0,
    ),
    ThemeTextStyleName.titleMedium: ThemeTextStyle(
      fontSize: 16,
      fontWeight: 'w500',
      lineHeight: 1.5,
      letterSpacing: 0.15,
    ),
    ThemeTextStyleName.titleSmall: ThemeTextStyle(
      fontSize: 14,
      fontWeight: 'w500',
      lineHeight: 1.43,
      letterSpacing: 0.1,
    ),
    ThemeTextStyleName.bodyLarge: ThemeTextStyle(
      fontSize: 16,
      fontWeight: 'w400',
      lineHeight: 1.5,
      letterSpacing: 0.5,
    ),
    ThemeTextStyleName.bodyMedium: ThemeTextStyle(
      fontSize: 14,
      fontWeight: 'w400',
      lineHeight: 1.43,
      letterSpacing: 0.25,
    ),
    ThemeTextStyleName.bodySmall: ThemeTextStyle(
      fontSize: 12,
      fontWeight: 'w400',
      lineHeight: 1.33,
      letterSpacing: 0.4,
    ),
    ThemeTextStyleName.labelLarge: ThemeTextStyle(
      fontSize: 14,
      fontWeight: 'w500',
      lineHeight: 1.43,
      letterSpacing: 0.1,
    ),
    ThemeTextStyleName.labelMedium: ThemeTextStyle(
      fontSize: 12,
      fontWeight: 'w500',
      lineHeight: 1.33,
      letterSpacing: 0.5,
    ),
    ThemeTextStyleName.labelSmall: ThemeTextStyle(
      fontSize: 11,
      fontWeight: 'w500',
      lineHeight: 1.45,
      letterSpacing: 0.5,
    ),
  },
  radii: {
    ThemeRadiusStep.extraSmall: 4,
    ThemeRadiusStep.small: 8,
    ThemeRadiusStep.medium: 12,
    ThemeRadiusStep.large: 16,
    ThemeRadiusStep.extraLarge: 28,
  },
  shadows: {
    ThemeShadowLevel.level1: ThemeShadow(
      color: '#33000000',
      offsetX: 0,
      offsetY: 1,
      blur: 2,
      spread: 0,
    ),
    ThemeShadowLevel.level2: ThemeShadow(
      color: '#33000000',
      offsetX: 0,
      offsetY: 2,
      blur: 6,
      spread: 0,
    ),
    ThemeShadowLevel.level3: ThemeShadow(
      color: '#33000000',
      offsetX: 0,
      offsetY: 4,
      blur: 12,
      spread: 0,
    ),
    ThemeShadowLevel.level4: ThemeShadow(
      color: '#33000000',
      offsetX: 0,
      offsetY: 6,
      blur: 16,
      spread: 0,
    ),
    ThemeShadowLevel.level5: ThemeShadow(
      color: '#33000000',
      offsetX: 0,
      offsetY: 8,
      blur: 24,
      spread: 0,
    ),
  },
);
