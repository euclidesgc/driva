import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/util/new_tab_launcher.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/demo_apk_download_block.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/preview_share_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingLauncher extends NewTabLauncher {
  const _RecordingLauncher(this.calls);

  final List<String> calls;

  @override
  void open(String url) {
    calls.add(url);
  }
}

const _demoApkUrl = 'https://exemplo.test/driva-demo-hml.apk';

const _warningText =
    'Este é um app de demonstração com um conteúdo fixo — não '
    'mostra o que você está editando agora.';

const _iphoneText = 'No iPhone, use o preview instalável acima.';

const _androidText =
    'O Android vai pedir permissão para instalar de fonte '
    'desconhecida. Se já tiver uma versão instalada, desinstale '
    'antes de instalar esta.';

Future<void> _pumpAndOpen(
  WidgetTester tester,
  Size size, {
  String demoApkUrl = '',
  NewTabLauncher launcher = const NewTabLauncher(),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => PreviewShareDialog(
              url: 'http://localhost:44723/preview/proj123/cont456',
              demoApkUrl: demoApkUrl,
              launcher: launcher,
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in const [Size(1280, 900), Size(1024, 600), Size(900, 500)]) {
    testWidgets('PreviewShareDialog monta em $size, sem URL, sem bloco', (
      tester,
    ) async {
      await _pumpAndOpen(tester, size);

      expect(find.text('Ver no celular'), findsOneWidget);
      expect(
        find.text('http://localhost:44723/preview/proj123/cont456'),
        findsOneWidget,
      );
      expect(find.byType(DemoApkDownloadBlock), findsNothing);
      expect(find.text('Baixar APK de teste'), findsNothing);
    });

    testWidgets('PreviewShareDialog em $size, com demoApkUrl, mostra o bloco', (
      tester,
    ) async {
      await _pumpAndOpen(tester, size, demoApkUrl: _demoApkUrl);

      if (size == const Size(900, 500)) {
        await tester.ensureVisible(find.text('Baixar APK de teste'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Baixar APK de teste'), findsOneWidget);
      expect(find.text(_warningText), findsOneWidget);
      expect(find.text(_iphoneText), findsOneWidget);
      expect(find.text(_androidText), findsOneWidget);
    });
  }

  testWidgets(
    'toca em Baixar APK de teste chama launcher.open com a URL de demoApkUrl',
    (tester) async {
      final calls = <String>[];

      await _pumpAndOpen(
        tester,
        const Size(1280, 900),
        demoApkUrl: _demoApkUrl,
        launcher: _RecordingLauncher(calls),
      );

      await tester.ensureVisible(find.text('Baixar APK de teste'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Baixar APK de teste'));
      await tester.pump();

      expect(calls, equals([_demoApkUrl]));
    },
  );
}
