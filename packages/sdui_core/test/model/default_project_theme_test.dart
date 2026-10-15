import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  const theme = kDefaultProjectTheme;

  test('cada papel de cor tem o valor do baseline Material 3', () {
    expect(theme.colors, {
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
    });
  });

  test('cada estilo de texto tem tamanho, peso, altura e espaçamento', () {
    const expected = <ThemeTextStyleName, (double, String, double, double)>{
      ThemeTextStyleName.displayLarge: (57, 'w400', 1.12, -0.25),
      ThemeTextStyleName.displayMedium: (45, 'w400', 1.16, 0),
      ThemeTextStyleName.displaySmall: (36, 'w400', 1.22, 0),
      ThemeTextStyleName.headlineLarge: (32, 'w400', 1.25, 0),
      ThemeTextStyleName.headlineMedium: (28, 'w400', 1.29, 0),
      ThemeTextStyleName.headlineSmall: (24, 'w400', 1.33, 0),
      ThemeTextStyleName.titleLarge: (22, 'w400', 1.27, 0),
      ThemeTextStyleName.titleMedium: (16, 'w500', 1.50, 0.15),
      ThemeTextStyleName.titleSmall: (14, 'w500', 1.43, 0.1),
      ThemeTextStyleName.bodyLarge: (16, 'w400', 1.50, 0.5),
      ThemeTextStyleName.bodyMedium: (14, 'w400', 1.43, 0.25),
      ThemeTextStyleName.bodySmall: (12, 'w400', 1.33, 0.4),
      ThemeTextStyleName.labelLarge: (14, 'w500', 1.43, 0.1),
      ThemeTextStyleName.labelMedium: (12, 'w500', 1.33, 0.5),
      ThemeTextStyleName.labelSmall: (11, 'w500', 1.45, 0.5),
    };

    expect(theme.textStyles.keys.toSet(), ThemeTextStyleName.values.toSet());
    for (final MapEntry(key: name, value: (size, weight, height, spacing))
        in expected.entries) {
      expect(
        theme.textStyles[name],
        ThemeTextStyle(
          fontSize: size,
          fontWeight: weight,
          lineHeight: height,
          letterSpacing: spacing,
        ),
        reason: name.name,
      );
    }
  });

  test('o tema padrão não define família da fonte', () {
    expect(
      theme.textStyles.values.map((s) => s.fontFamily),
      everyElement(isNull),
    );
  });

  test('a escala de raio é a de forma do Material 3', () {
    expect(theme.radii, {
      ThemeRadiusStep.extraSmall: 4,
      ThemeRadiusStep.small: 8,
      ThemeRadiusStep.medium: 12,
      ThemeRadiusStep.large: 16,
      ThemeRadiusStep.extraLarge: 28,
    });
  });

  test('cada nível de sombra cresce em deslocamento e desfoque', () {
    const expected = <ThemeShadowLevel, (double, double)>{
      ThemeShadowLevel.level1: (1, 2),
      ThemeShadowLevel.level2: (2, 6),
      ThemeShadowLevel.level3: (4, 12),
      ThemeShadowLevel.level4: (6, 16),
      ThemeShadowLevel.level5: (8, 24),
    };

    expect(theme.shadows.keys.toSet(), ThemeShadowLevel.values.toSet());
    for (final MapEntry(key: level, value: (offsetY, blur))
        in expected.entries) {
      expect(
        theme.shadows[level],
        ThemeShadow(
          color: '#33000000',
          offsetX: 0,
          offsetY: offsetY,
          blur: blur,
          spread: 0,
        ),
        reason: level.name,
      );
    }
  });

  test('todos os mapas têm todas as chaves do enum', () {
    expect(theme.colors.keys.toSet(), ThemeColorRole.values.toSet());
    expect(theme.radii.keys.toSet(), ThemeRadiusStep.values.toSet());
  });

  group('toJson', () {
    test('tem as 4 chaves de topo e as internas na ordem do enum', () {
      final json = theme.toJson();

      expect(json.keys.toList(), ['colors', 'textStyles', 'radii', 'shadows']);
      expect(
        (json['colors'] as Map).keys.toList(),
        ThemeColorRole.values.map((e) => e.name).toList(),
      );
      expect(
        (json['textStyles'] as Map).keys.toList(),
        ThemeTextStyleName.values.map((e) => e.name).toList(),
      );
      expect(
        (json['radii'] as Map).keys.toList(),
        ThemeRadiusStep.values.map((e) => e.name).toList(),
      );
      expect(
        (json['shadows'] as Map).keys.toList(),
        ThemeShadowLevel.values.map((e) => e.name).toList(),
      );
      expect((json['colors'] as Map)['primary'], '#6750A4');
      expect((json['textStyles'] as Map)['bodyMedium'], {
        'fontSize': 14,
        'fontWeight': 'w400',
        'lineHeight': 1.43,
        'letterSpacing': 0.25,
      });
      expect((json['shadows'] as Map)['level1'], {
        'color': '#33000000',
        'offsetX': 0,
        'offsetY': 1,
        'blur': 2,
        'spread': 0,
      });
    });

    test(
      'ThemeTextStyle omite fontFamily quando nula e inclui quando existe',
      () {
        const plain = ThemeTextStyle(
          fontSize: 14,
          fontWeight: 'w400',
          lineHeight: 1.43,
          letterSpacing: 0.25,
        );
        const withFamily = ThemeTextStyle(
          fontSize: 14,
          fontWeight: 'w400',
          lineHeight: 1.43,
          letterSpacing: 0.25,
          fontFamily: 'Inter',
        );

        expect(plain.toJson().containsKey('fontFamily'), isFalse);
        expect(withFamily.toJson()['fontFamily'], 'Inter');
      },
    );
  });
}
