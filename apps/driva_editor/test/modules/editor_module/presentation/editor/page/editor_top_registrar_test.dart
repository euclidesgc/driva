import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_status_indicator.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_top_bar.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:driva_editor/modules/editor_module/domain/use_cases/use_cases.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/editor_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_controller.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_layout_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/editor_top_registrar.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/versions/version_history_dialog.dart';
import 'package:driva_editor/modules/projects_module/projects_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../support/app_fonts.dart';

class _MockLoadContentUseCase extends Mock implements LoadContentUseCase {}

class _MockSaveDraftUseCase extends Mock implements SaveDraftUseCase {}

class _MockPublishContentUseCase extends Mock
    implements PublishContentUseCase {}

class _MockUnpublishContentUseCase extends Mock
    implements UnpublishContentUseCase {}

class _MockRestoreContentVersionUseCase extends Mock
    implements RestoreContentVersionUseCase {}

class _MockEditorRepository extends Mock implements EditorRepository {}

class _MockGetContentVersionsUseCase extends Mock
    implements GetContentVersionsUseCase {}

class _MockGetContentVersionUseCase extends Mock
    implements GetContentVersionUseCase {}

const ContentSpec _publishedDoc = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'nd_root',
    type: 'column',
    children: [SduiNode(id: 'nd_text', type: 'text')],
  ),
);

/// Substituto do `ThemeModeButton` real (fora deste módulo, precisaria de
/// `ThemeCubit`) do mesmo tamanho de toque que ele renderiza — sem isso a
/// barra mediria menos largura do que a real e esconderia overflow.
const _themeButtonStandIn = SizedBox(
  width: kMinInteractiveDimension,
  height: kMinInteractiveDimension,
);

/// Os três textos que `AppShellStatusIndicator` pode mostrar têm larguras
/// bem diferentes — calibrar a barra olhando só um deles é o que já
/// escondeu overflow antes (o indicador virou `Flexible`, mas o teste
/// continua provando que nenhum dos três estoura).
final _publicationStates = {
  'no ar': const PublicationState(
    hasUnpublishedChanges: false,
    publishedVersion: 3,
    latestVersion: 3,
  ),
  'fora do ar': const PublicationState(
    hasUnpublishedChanges: true,
    latestVersion: 3,
  ),
  'alterações não publicadas': const PublicationState(
    hasUnpublishedChanges: true,
    publishedVersion: 3,
    latestVersion: 3,
  ),
};

Future<EditorCubit> _pumpBarAt(
  WidgetTester tester,
  PublicationState publication,
  double width, {
  bool withCompareModeScope = true,
  GetContentVersionsUseCase? getContentVersionsUseCase,
  GetContentVersionUseCase? getContentVersionUseCase,
}) async {
  final cubit =
      EditorCubit(
        loadContentUseCase: _MockLoadContentUseCase(),
        saveDraftUseCase: _MockSaveDraftUseCase(),
        publishContentUseCase: _MockPublishContentUseCase(),
        unpublishContentUseCase: _MockUnpublishContentUseCase(),
        restoreContentVersionUseCase: _MockRestoreContentVersionUseCase(),
        projectId: 'p1',
      )..emit(
        EditorReady(
          document: _publishedDoc,
          canUndo: true,
          canRedo: true,
          publication: publication,
        ),
      );
  final layoutController = EditorLayoutController();
  final shellController = AppShellController();
  final versionsUseCase =
      getContentVersionsUseCase ??
      GetContentVersionsUseCase(repository: _MockEditorRepository());
  final versionUseCase =
      getContentVersionUseCase ??
      GetContentVersionUseCase(repository: _MockEditorRepository());
  // Reproduz `EditorWorkspaceHost`: quando os dois use cases de versão
  // chegam, o soquete do modo de comparação é sempre instalado acima do
  // topo do editor — sem ele o botão de Histórico nasce indisponível.
  final compareModeCubit = withCompareModeScope
      ? VersionCompareModeCubit(
          getContentVersionUseCase: versionUseCase,
          getContentVersionsUseCase: versionsUseCase,
          editorCubit: cubit,
        )
      : null;
  addTearDown(cubit.close);
  addTearDown(layoutController.dispose);
  addTearDown(shellController.dispose);
  addTearDown(() => compareModeCubit?.close());

  await tester.binding.setSurfaceSize(Size(width, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final registrar = EditorTopRegistrar(
    projectFuture: Future<Either<Failure, Project>>.value(
      const Left(UnexpectedFailure()),
    ),
    getContentVersionsUseCase: versionsUseCase,
    getContentVersionUseCase: versionUseCase,
    child: const SizedBox.shrink(),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: AppShellScope(
        controller: shellController,
        child: Column(
          children: [
            const AppShellTopBar(
              homeRouteName: 'home',
              themeButton: _themeButtonStandIn,
            ),
            Expanded(
              child: BlocProvider<EditorCubit>.value(
                value: cubit,
                child: EditorLayoutScope(
                  controller: layoutController,
                  child: compareModeCubit == null
                      ? registrar
                      : VersionCompareModeScope(
                          cubit: compareModeCubit,
                          child: registrar,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

void main() {
  setUpAll(loadAppFonts);

  // Larguras generosas, e não um limiar: o colapso é decidido contando as
  // ações que a barra tem, então o teste cobra que, com espaço de sobra, nada
  // some nem vaza — não onde fica o ponto de virada, que muda com o conjunto
  // de ações e é justamente o que a conta automática existe para acompanhar.
  for (final stateEntry in _publicationStates.entries) {
    for (final width in [1100.0, 1300.0, 1600.0]) {
      testWidgets(
        'estado "${stateEntry.key}" em ${width}px cabe sem overflow, com '
        'Despublicar/Histórico/status inteiramente na tela e sem menu',
        (tester) async {
          await _pumpBarAt(tester, stateEntry.value, width);

          expect(tester.takeException(), isNull);
          expect(find.byIcon(Icons.more_vert), findsNothing);

          final despublicar = find.byIcon(Icons.visibility_off_outlined);
          final historico = find.byTooltip('Histórico de versões');
          final status = find.byType(AppShellStatusIndicator);

          expect(despublicar, findsOneWidget);
          expect(historico, findsOneWidget);
          expect(status, findsOneWidget);

          for (final MapEntry(key: label, value: finder) in {
            'Despublicar': despublicar,
            'Histórico': historico,
            'Status': status,
          }.entries) {
            final rect = tester.getRect(finder);
            expect(
              rect.left >= 0 && rect.right <= width,
              isTrue,
              reason:
                  '$label saiu da tela em ${width}px (estado '
                  '"${stateEntry.key}"): left=${rect.left}, '
                  'right=${rect.right}',
            );
          }
        },
      );
    }
  }

  for (final width in [480.0, 700.0]) {
    testWidgets(
      'em ${width}px, largura em que a barra cheia não cabe, ela nunca '
      'estoura: '
      'vira um único menu do shell, sem menu dentro de menu, e '
      'Despublicar/Histórico continuam alcançáveis nele',
      (tester) async {
        await _pumpBarAt(
          tester,
          _publicationStates['alterações não publicadas']!,
          width,
        );

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
        expect(find.byTooltip('Histórico de versões'), findsNothing);
        expect(find.text('Salvar'), findsNothing);

        final overflowButton = find.byTooltip('Mais ações');
        expect(overflowButton, findsOneWidget);

        await tester.tap(overflowButton);
        await tester.pumpAndSettle();

        expect(find.text('Despublicar'), findsOneWidget);
        expect(find.text('Histórico'), findsOneWidget);
        expect(find.byTooltip('Mais opções'), findsNothing);
      },
    );
  }

  group('clique em Histórico', () {
    late _MockGetContentVersionsUseCase getContentVersionsUseCase;
    late _MockGetContentVersionUseCase getContentVersionUseCase;

    setUp(() {
      getContentVersionsUseCase = _MockGetContentVersionsUseCase();
      getContentVersionUseCase = _MockGetContentVersionUseCase();
      when(
        () => getContentVersionsUseCase('ct_1'),
      ).thenAnswer((_) async => const Right(ContentVersionsPage(items: [])));
    });

    testWidgets(
      'com o modo de comparação disponível no contexto, abre o '
      'VersionHistoryDialog',
      (tester) async {
        await _pumpBarAt(
          tester,
          _publicationStates['no ar']!,
          1600,
          getContentVersionsUseCase: getContentVersionsUseCase,
          getContentVersionUseCase: getContentVersionUseCase,
        );

        await tester.tap(find.byTooltip('Histórico de versões'));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(VersionHistoryDialog), findsOneWidget);
      },
    );

    testWidgets(
      'sem o modo de comparação no contexto, o botão nasce indisponível e o '
      'clique não derruba a aplicação',
      (tester) async {
        await _pumpBarAt(
          tester,
          _publicationStates['no ar']!,
          1600,
          withCompareModeScope: false,
          getContentVersionsUseCase: getContentVersionsUseCase,
          getContentVersionUseCase: getContentVersionUseCase,
        );

        final button = find.byTooltip('Histórico de versões (indisponível)');
        expect(button, findsOneWidget);

        await tester.tap(button, warnIfMissed: false);
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(VersionHistoryDialog), findsNothing);
      },
    );
  });

  group('rascunho congelado pelo modo de comparação', () {
    Finder enabledButtonWithLabel(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (widget) => widget is ButtonStyleButton && widget.onPressed != null,
      ),
    );

    testWidgets('escrever sai da barra; Histórico continua', (tester) async {
      final cubit = await _pumpBarAt(
        tester,
        _publicationStates['no ar']!,
        1600,
      );

      expect(enabledButtonWithLabel('Salvar'), findsOneWidget);
      expect(enabledButtonWithLabel('Publicar'), findsOneWidget);

      cubit.setReadOnly(value: true);
      await tester.pumpAndSettle();

      expect(enabledButtonWithLabel('Salvar'), findsNothing);
      expect(enabledButtonWithLabel('Publicar'), findsNothing);
      expect(enabledButtonWithLabel('Histórico'), findsOneWidget);
      expect(
        find.byTooltip('Comparando versões — feche a comparação para editar'),
        findsWidgets,
      );
    });

    testWidgets('descongelado, Salvar e Publicar voltam', (tester) async {
      final cubit = await _pumpBarAt(
        tester,
        _publicationStates['no ar']!,
        1600,
      );

      cubit
        ..setReadOnly(value: true)
        ..setReadOnly(value: false);
      await tester.pumpAndSettle();

      expect(enabledButtonWithLabel('Salvar'), findsOneWidget);
      expect(enabledButtonWithLabel('Publicar'), findsOneWidget);
    });
  });
}
