import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_review_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_dialog.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_fullscreen_shell.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_review_windowed_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

class MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

void main() {
  late MockGetContentVersionUseCase getContentVersion;

  const spec = ContentSpec(
    specVersion: kSpecVersion,
    id: 'ct_1',
    name: 'Home',
    slug: 'home',
    root: SduiNode(id: 'nd_root', type: 'text', properties: {'data': 'Oi'}),
  );

  final loaded = LoadedContentVersion(
    version: 5,
    spec: spec,
    createdAt: DateTime.utc(2026, 8, 16, 12, 30),
    note: 'Ajuste no banner',
  );

  setUp(() => getContentVersion = MockGetContentVersionUseCase());

  VersionReviewCubit buildCubit() => VersionReviewCubit(
    getContentVersionUseCase: getContentVersion,
    contentId: 'ct_1',
    version: 5,
  );

  Future<void> pumpDialog(WidgetTester tester, VersionReviewCubit cubit) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider.value(
            value: cubit,
            child: const VersionReviewDialog(),
          ),
        ),
      );

  testWidgets('carregando: mostra spinner, sem crash', (tester) async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await pumpDialog(tester, cubit);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('falha: mostra mensagem e permite tentar de novo sem fechar', (
    tester,
  ) async {
    when(
      () => getContentVersion('ct_1', 5),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await pumpDialog(tester, cubit);
    await cubit.load();
    await tester.pump();

    expect(find.text('Esta versão não existe mais.'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Tentar de novo'));
    await tester.pump();

    verify(() => getContentVersion('ct_1', 5)).called(2);
  });

  testWidgets(
    'sucesso: mostra número, data, nota e o selo Somente leitura',
    (tester) async {
      when(
        () => getContentVersion('ct_1', 5),
      ).thenAnswer((_) async => Right(loaded));
      final cubit = buildCubit();
      addTearDown(cubit.close);
      await pumpDialog(tester, cubit);
      await cubit.load();
      await tester.pump();

      expect(find.textContaining('Versão 5'), findsOneWidget);
      expect(find.textContaining('16/08/2026'), findsOneWidget);
      expect(find.text('Ajuste no banner'), findsOneWidget);
      expect(find.text('Somente leitura'), findsOneWidget);
    },
  );

  testWidgets('desktop: usa a moldura larga (AlertDialog)', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = buildCubit();
    addTearDown(cubit.close);
    await pumpDialog(tester, cubit);

    expect(find.byType(VersionReviewWindowedShell), findsOneWidget);
    expect(find.byType(VersionReviewFullscreenShell), findsNothing);
  });

  testWidgets('compacto: ocupa a tela inteira', (tester) async {
    tester.view.physicalSize = const Size(700, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = buildCubit();
    addTearDown(cubit.close);
    await pumpDialog(tester, cubit);

    expect(find.byType(VersionReviewFullscreenShell), findsOneWidget);
    expect(find.byType(VersionReviewWindowedShell), findsNothing);
  });
}
