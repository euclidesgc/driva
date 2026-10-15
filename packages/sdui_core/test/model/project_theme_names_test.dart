import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  test('os 16 papéis de cor são os do contrato, na ordem', () {
    expect(ThemeColorRole.values.map((e) => e.name).toList(), [
      'primary',
      'secondary',
      'tertiary',
      'alternate',
      'primaryText',
      'secondaryText',
      'primaryBackground',
      'secondaryBackground',
      'accent1',
      'accent2',
      'accent3',
      'accent4',
      'success',
      'warning',
      'error',
      'info',
    ]);
  });

  test('os 15 estilos de texto são os do contrato, na ordem', () {
    expect(ThemeTextStyleName.values.map((e) => e.name).toList(), [
      'displayLarge',
      'displayMedium',
      'displaySmall',
      'headlineLarge',
      'headlineMedium',
      'headlineSmall',
      'titleLarge',
      'titleMedium',
      'titleSmall',
      'bodyLarge',
      'bodyMedium',
      'bodySmall',
      'labelLarge',
      'labelMedium',
      'labelSmall',
    ]);
  });

  test('os 5 passos de raio são os do contrato, na ordem', () {
    expect(ThemeRadiusStep.values.map((e) => e.name).toList(), [
      'extraSmall',
      'small',
      'medium',
      'large',
      'extraLarge',
    ]);
  });

  test('os 5 níveis de sombra são os do contrato, na ordem', () {
    expect(ThemeShadowLevel.values.map((e) => e.name).toList(), [
      'level1',
      'level2',
      'level3',
      'level4',
      'level5',
    ]);
  });

  group('fromName', () {
    test('acha o valor pelo nome do JSON', () {
      expect(
        ThemeColorRole.fromName('primaryText'),
        ThemeColorRole.primaryText,
      );
      expect(
        ThemeTextStyleName.fromName('bodyMedium'),
        ThemeTextStyleName.bodyMedium,
      );
      expect(
        ThemeRadiusStep.fromName('extraLarge'),
        ThemeRadiusStep.extraLarge,
      );
      expect(ThemeShadowLevel.fromName('level3'), ThemeShadowLevel.level3);
    });

    test('nome desconhecido devolve null', () {
      expect(ThemeColorRole.fromName('brand'), isNull);
      expect(ThemeTextStyleName.fromName('brand'), isNull);
      expect(ThemeRadiusStep.fromName('brand'), isNull);
      expect(ThemeShadowLevel.fromName('brand'), isNull);
    });
  });
}
