import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_breadcrumb_bar.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(AppShellController controller) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: AppShellScope(
      controller: controller,
      child: const AppShellBreadcrumbBar(),
    ),
  ),
);

void main() {
  testWidgets(
    'a 1280px o último crumb de ~80 caracteres trunca com reticências, em '
    'uma linha, sem estourar a Row',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final longName = 'Conteúdo com nome bem comprido ' * 3;
      final controller = AppShellController()
        ..publish(
          Object(),
          crumbs: [
            const Crumb(label: 'Projetos', routeName: 'projects'),
            const Crumb(label: 'Projeto', routeName: 'project'),
            Crumb(label: longName),
          ],
          actions: const [],
        );

      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final textFinder = find.text(longName);
      expect(textFinder, findsOneWidget);
      final text = tester.widget<Text>(textFinder);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    },
  );
}
