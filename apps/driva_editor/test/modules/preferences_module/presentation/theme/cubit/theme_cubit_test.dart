import 'package:bloc_test/bloc_test.dart';
import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/preferences_module/domain/entities/app_theme_mode.dart';
import 'package:driva_editor/modules/preferences_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/preferences_module/presentation/theme/cubit/theme_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetThemeModeUseCase extends Mock implements GetThemeModeUseCase {}

class MockSaveThemeModeUseCase extends Mock implements SaveThemeModeUseCase {}

void main() {
  late MockGetThemeModeUseCase getThemeMode;
  late MockSaveThemeModeUseCase saveThemeMode;

  setUpAll(() => registerFallbackValue(AppThemeMode.system));

  setUp(() {
    getThemeMode = MockGetThemeModeUseCase();
    saveThemeMode = MockSaveThemeModeUseCase();
  });

  ThemeCubit build() =>
      ThemeCubit(getThemeMode: getThemeMode, saveThemeMode: saveThemeMode);

  test('estado inicial é system', () {
    expect(build().state, const ThemeState(AppThemeMode.system));
  });

  group('load', () {
    blocTest<ThemeCubit, ThemeState>(
      'emite o modo persistido',
      build: build,
      setUp: () => when(
        () => getThemeMode(),
      ).thenAnswer((_) async => const Right(AppThemeMode.dark)),
      act: (cubit) => cubit.load(),
      expect: () => [const ThemeState(AppThemeMode.dark)],
    );

    blocTest<ThemeCubit, ThemeState>(
      'falha de leitura mantém o padrão (system), sem derrubar a app',
      build: build,
      setUp: () => when(
        () => getThemeMode(),
      ).thenAnswer((_) async => const Left(UnexpectedFailure())),
      act: (cubit) => cubit.load(),
      expect: () => [const ThemeState(AppThemeMode.system)],
    );
  });

  group('setMode', () {
    blocTest<ThemeCubit, ThemeState>(
      'aplica na hora e persiste',
      build: build,
      setUp: () => when(
        () => saveThemeMode(AppThemeMode.light),
      ).thenAnswer((_) async => const Right(unit)),
      act: (cubit) => cubit.setMode(AppThemeMode.light),
      expect: () => [const ThemeState(AppThemeMode.light)],
      verify: (_) => verify(() => saveThemeMode(AppThemeMode.light)).called(1),
    );

    blocTest<ThemeCubit, ThemeState>(
      'modo igual ao atual não reemite nem persiste',
      build: build,
      act: (cubit) => cubit.setMode(AppThemeMode.system),
      expect: () => <ThemeState>[],
      verify: (_) => verifyNever(() => saveThemeMode(any())),
    );
  });
}
