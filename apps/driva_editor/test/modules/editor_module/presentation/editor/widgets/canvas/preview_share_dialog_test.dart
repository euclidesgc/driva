import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/preview_share_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(1280, 900), Size(1024, 600), Size(900, 500)]) {
    testWidgets('PreviewShareDialog monta em $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const PreviewShareDialog(
                  url: 'http://localhost:44723/preview/proj123/cont456',
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Ver no celular'), findsOneWidget);
      expect(
        find.text('http://localhost:44723/preview/proj123/cont456'),
        findsOneWidget,
      );
    });
  }
}
