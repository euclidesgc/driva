import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/device_preset.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/canvas/canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../../support/golden.dart';

const _candidateSpec = ContentSpec(
  specVersion: kSpecVersion,
  id: 'ct_1',
  name: 'Home',
  slug: 'home',
  root: SduiNode(
    id: 'nd_root',
    type: 'column',
    children: [
      SduiNode(
        id: 'nd_title',
        type: 'text',
        properties: {'data': 'Promoção de inverno'},
      ),
      SduiNode(
        id: 'nd_cta',
        type: 'button',
        properties: {'label': 'Ver ofertas'},
      ),
    ],
  ),
);

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await installTolerantGoldenComparator();
  });

  testWidgets('mock da versão comparada, com a barra da candidata', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(620, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: VersionCompareMockPane(
            device: DevicePreset.smartphone,
            effectiveScale: 0.55,
            spec: _candidateSpec,
            candidateVersion: 3,
            onOlder: () {},
            onNewer: () {},
            onLoadFullVersion: () {},
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(VersionCompareMockPane),
      matchesGoldenFile('goldens/version_compare_mock_pane.png'),
    );
  });

  testWidgets(
    'a barra da candidata em faixa estreita solta os rótulos e mantém os '
    'controles',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 120));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: VersionCompareCandidateBar(
              candidateVersion: 3,
              onOlder: () {},
              onNewer: () {},
              onLoadFullVersion: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tolerância apertada: o alvo aqui é justamente o rótulo que some ou
      // trunca, e ele ocupa uma fração pequena da imagem — no teto padrão de
      // 5% a regressão passaria batida.
      await withStricterGolden(0.01, () async {
        await expectLater(
          find.byType(VersionCompareCandidateBar),
          matchesGoldenFile(
            'goldens/version_compare_candidate_bar_compact.png',
          ),
        );
      });
    },
  );
}
