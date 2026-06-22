import 'package:device_frame_plus/device_frame_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_preview/src/device_catalog.dart';
import 'package:sdui_preview/src/device_preview.dart';

/// Monta um [DevicePreview] e devolve o [MediaQueryData] que o `child` enxerga
/// — ou seja, o **simulado**. É a prova dos critérios de aceite: o widget lê os
/// valores do aparelho, não os da janela real.
Future<MediaQueryData> _capture(
  WidgetTester tester, {
  required DeviceInfo device,
  required Orientation orientation,
  Brightness brightness = Brightness.light,
  bool showFrame = false,
  // Por padrão SEM SafeArea: os testes de injeção querem ver o MediaQuery
  // injetado cru. O comportamento do SafeArea é coberto em grupo próprio.
  bool safeArea = false,
  double textScaleFactor = 1.0,
}) async {
  late MediaQueryData captured;
  await tester.pumpWidget(
    MaterialApp(
      home: DevicePreview(
        device: device,
        orientation: orientation,
        brightness: brightness,
        showFrame: showFrame,
        safeArea: safeArea,
        textScaleFactor: textScaleFactor,
        child: Builder(
          builder: (context) {
            captured = MediaQuery.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return captured;
}

void main() {
  group('DevicePreview — caminho leve (sem moldura)', () {
    testWidgets('injeta size/densidade/safe area/brilho do aparelho (retrato)',
        (tester) async {
      final d = DeviceCatalog.iphone;
      final mq = await _capture(
        tester,
        device: d,
        orientation: Orientation.portrait,
      );

      expect(mq.size, d.screenSize);
      expect(mq.devicePixelRatio, d.pixelRatio);
      expect(mq.padding, d.safeAreas);
      expect(mq.platformBrightness, Brightness.light);
    });

    testWidgets('landscape inverte o size e usa rotatedSafeAreas',
        (tester) async {
      final d = DeviceCatalog.iphone;
      final mq = await _capture(
        tester,
        device: d,
        orientation: Orientation.landscape,
      );

      expect(mq.size, Size(d.screenSize.height, d.screenSize.width));
      expect(mq.padding, d.rotatedSafeAreas);
    });

    testWidgets('aparelho que não rotaciona (web/desktop) ignora o landscape',
        (tester) async {
      final d = DeviceCatalog.webDesktop;
      expect(d.canRotate, isFalse);

      final mq = await _capture(
        tester,
        device: d,
        orientation: Orientation.landscape,
      );

      expect(mq.size, d.screenSize); // não invertido
      expect(mq.devicePixelRatio, 1.0);
    });

    testWidgets('brilho escuro vira platformBrightness dark', (tester) async {
      final mq = await _capture(
        tester,
        device: DeviceCatalog.iphone,
        orientation: Orientation.portrait,
        brightness: Brightness.dark,
      );
      expect(mq.platformBrightness, Brightness.dark);
    });

    testWidgets('textScaleFactor reflete no textScaler', (tester) async {
      final mq = await _capture(
        tester,
        device: DeviceCatalog.iphone,
        orientation: Orientation.portrait,
        textScaleFactor: 1.5,
      );
      expect(mq.textScaler.scale(10), 15);
    });
  });

  group('DevicePreview — safe area', () {
    testWidgets('ligada: recua o conteúdo (filho vê padding zero)',
        (tester) async {
      final d = DeviceCatalog.iphone;
      expect(d.safeAreas.top, greaterThan(0)); // sanity: iPhone tem notch

      final mq = await _capture(
        tester,
        device: d,
        orientation: Orientation.portrait,
        safeArea: true,
      );
      // O SafeArea consumiu o padding antes do widget — o notch não invade.
      expect(mq.padding, EdgeInsets.zero);
    });

    testWidgets('desligada: conteúdo edge-to-edge (padding intacto)',
        (tester) async {
      final d = DeviceCatalog.iphone;
      final mq = await _capture(
        tester,
        device: d,
        orientation: Orientation.portrait,
        safeArea: false,
      );
      expect(mq.padding, d.safeAreas);
    });
  });

  group('DevicePreview — com moldura (DeviceFrame)', () {
    testWidgets('o DeviceFrame injeta o size do aparelho (sem dupla injeção)',
        (tester) async {
      final d = DeviceCatalog.iphone;
      final mq = await _capture(
        tester,
        device: d,
        orientation: Orientation.portrait,
        showFrame: true,
      );

      expect(mq.size, d.screenSize);
      expect(mq.devicePixelRatio, d.pixelRatio);
      // brilho/escala são preservados pelo DeviceFrame a partir do ambiente.
      expect(mq.platformBrightness, Brightness.light);
    });
  });

  group('DeviceCatalog', () {
    test('defaultDevice é uma instância presente em all (identidade estável)',
        () {
      expect(DeviceCatalog.all, contains(DeviceCatalog.defaultDevice));
    });

    test('cobre 5 categorias; web/desktop não rotaciona, phone rotaciona', () {
      expect(DeviceCatalog.all.length, 5);
      expect(DeviceCatalog.webDesktop.canRotate, isFalse);
      expect(DeviceCatalog.iphone.canRotate, isTrue);
    });
  });
}
