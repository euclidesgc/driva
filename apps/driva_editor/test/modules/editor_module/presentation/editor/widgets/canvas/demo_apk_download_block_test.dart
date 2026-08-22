import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/util/new_tab_launcher.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/demo_apk_download_block.dart';
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

void main() {
  const url = 'https://example.test/demo.apk';

  testWidgets('toca o botão chama launcher.open com a URL exata', (
    tester,
  ) async {
    final calls = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DemoApkDownloadBlock(
            url: url,
            launcher: _RecordingLauncher(calls),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Baixar APK de teste'));
    await tester.pump();

    expect(calls, equals([url]));
  });

  testWidgets('expõe nó de semântica com rótulo Baixar APK de teste', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: DemoApkDownloadBlock(url: url)),
      ),
    );

    expect(
      find.bySemanticsLabel('Baixar APK de teste'),
      findsOneWidget,
    );

    handle.dispose();
  });
}
