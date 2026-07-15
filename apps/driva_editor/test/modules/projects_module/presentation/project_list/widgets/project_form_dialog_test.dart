import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/projects_module/presentation/project_list/widgets/project_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Regressão: `Spacer` nos `actions` (um `OverflowBar`, não Flex) virava
/// RenderErrorBox — retângulo cinza em release.
void main() {
  Future<void> pumpDialog(WidgetTester tester, {required bool editMode}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => ProjectFormDialog(
                    title: editMode ? 'Editar projeto' : 'Novo projeto',
                    initialTitle: editMode ? 'Projeto' : null,
                    onSubmit: (_) async => const Left(UnexpectedFailure()),
                    onArchive: editMode
                        ? () async => const Left(UnexpectedFailure())
                        : null,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('monta no modo criar sem exceção', (tester) async {
    await pumpDialog(tester, editMode: false);
    expect(tester.takeException(), isNull);
    expect(find.text('Salvar projeto'), findsOneWidget);
    expect(find.text('Arquivar'), findsNothing);
  });

  testWidgets('monta no modo editar (com Arquivar) sem exceção', (
    tester,
  ) async {
    await pumpDialog(tester, editMode: true);
    expect(tester.takeException(), isNull);
    expect(find.text('Salvar projeto'), findsOneWidget);
    expect(find.text('Arquivar'), findsOneWidget);
  });
}
